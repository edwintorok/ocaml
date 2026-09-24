(* TEST
 include runtime_events;
*)
open Runtime_events

let t0 = Timestamp.get_current () |> Timestamp.to_int64 |> Int64.to_int

type User.tag += Workload

let workload = User.register "workload" Workload Type.span

let workload_finally () = User.write workload Type.End

let with_workload f =
  User.write workload Type.Begin;
  Fun.protect ~finally:workload_finally f

type User.tag += Srcline
let srcline = User.register "srcline" Srcline Type.int
let line ~__LINE__ = User.write srcline __LINE__

type User.tag += Gc_stat_observed
let gc_stat_observed = User.register "gc_stat_observed" Gc_stat_observed Type.int
let[@inline] gc_observed value = User.write gc_stat_observed value

let () = start ()

let poll cursor callbacks =
    while read_poll cursor callbacks None > 0 do () done

module Dump = struct
  (* Separate cursor, used only when debugging a failure to see
     the event history *)
  let cursor = create_cursor None

  let pp_timestamp ppf ts =
    let dt =
      1e-9 *.
      ((ts |> Timestamp.to_int64 |> Int64.to_int) - t0
      |> float_of_int)
    in
    Format.fprintf ppf "%.9f s" dt

  let indent = ref 1

  let header domain_id timestamp  =
    Format.eprintf "[%a][% 3d]%*s " pp_timestamp timestamp domain_id
      (!indent) ""

  let runtime_phase domain_id timestamp phase kind =
    header domain_id timestamp;
    Format.eprintf "%s %s@," kind (runtime_phase_name phase)

  let runtime_begin domain_id timestamp phase =
    runtime_phase domain_id timestamp phase ">";
    incr indent

  let runtime_end domain_id timestamp phase =
    decr indent;
    runtime_phase domain_id timestamp phase "<"

  let runtime_counter domain_id timestamp counter value =
    header domain_id timestamp;
    Format.eprintf "%37s =% 19d@," (runtime_counter_name counter) value

  let lifecycle domain_id timestamp lifecycle arg =
    header domain_id timestamp;
    Format.eprintf "%s %a@," (lifecycle_name lifecycle) Format.(pp_print_option Format.pp_print_int) arg

  let lost_events domain_id lost_words=
    header domain_id (Timestamp.get_current ());
    Format.eprintf "LOST EVENTS: %d words@," lost_words

  let user_span domain_id timestamp user value =
    let c = if value = Type.Begin then '>' else '<' in
    if value = Type.End then decr indent;
    header domain_id timestamp;
    Format.eprintf "%c %s@," c (User.name user);
    if value = Type.Begin then incr indent

  let user_int domain_id timestamp user value =
    header domain_id timestamp;
    Format.eprintf "%s=%d@," (User.name user) value

  let callbacks = Callbacks.create
    ~runtime_begin
    ~runtime_end
    ~runtime_counter
    ~lifecycle
    ~lost_events ()
    |> Callbacks.add_user_event Type.span user_span
    |> Callbacks.add_user_event Type.int user_int

  let noop = Callbacks.create ()

  let drop () = poll cursor noop


  let dump () =
    Format.printf "@.";
    Format.eprintf "@.%s@." (String.make 78 '=');
    Format.eprintf "@[<v>";
    poll cursor callbacks;
    Format.eprintf "@]@."
end

let lost_events_fail domain_id lost_words=
  Format.asprintf "[% 3d] LOST %d words in events" domain_id lost_words
  |> failwith

type counter_type = Additive | Absolute

let run_and_compare ~__LINE__ f counter_expected counter_type observe_gc =
  let counter_value = ref 0 in
  let runtime_counter domain_id timestamp counter value =
    if counter = counter_expected then
      if counter_type = Additive then
        counter_value := !counter_value + value
      else
        counter_value := value
  in
  let callbacks = Callbacks.create
    ~runtime_counter
    ~lost_events:lost_events_fail ()
  in
  (* start fresh, but don't yet count these *)
  Gc.compact ();
  Dump.drop ();
  line ~__LINE__;
  let cursor = create_cursor None in
  let finally () = free_cursor cursor in
  Fun.protect ~finally @@ fun () ->
  let observe () =
    (* major GC counters are only emitted if a major slice occurred *)
    let _ : int = Gc.major_slice 0 in
    (* polling allocates int64 timestamps, so flush any events here where both can see them *)
    poll cursor callbacks;
    (* ensure stats are up-to-date for [quick_stat] *)
    Gc.minor ();
    let gc = Gc.quick_stat () |> observe_gc in
    (* polling allocates int64 timestamps, so run final one after *)
    poll cursor callbacks;
    (* this may allocate (when processed), so run after *)
    gc_observed gc;
    let counter = !counter_value in
    gc, counter
  in
  let baseline_gc, baseline_counter = observe () in
  with_workload f;
  let after_gc, after_counter = observe () in
  let delta_gc = after_gc - baseline_gc
  and delta_counter = after_counter - baseline_counter in
  delta_gc, delta_counter

let run_and_compare_test ~__LINE__ f counter_expected counter_type observe_gc expected_value_geq=
  let delta_gc, delta_counter = run_and_compare ~__LINE__:Stdlib.__LINE__ ignore counter_expected counter_type observe_gc in
  let tol = abs (delta_gc - delta_counter) in
  if tol > delta_gc then begin
    Dump.dump ();
    Format.eprintf "[!] Runtime counter value %s on no-op workload: %+d, GC counter value: %+d@."
      (runtime_counter_name counter_expected)
      delta_counter delta_gc;
  end;
  let delta_gc, delta_counter = run_and_compare ~__LINE__ f counter_expected counter_type observe_gc in
  let bad = ref false in
  let log fmt =
    bad := true;
    Dump.dump ();
    let finish ppf = Format.fprintf ppf "@." in
    Format.eprintf "[!] ";
    Format.kfprintf finish Format.err_formatter fmt
  in
  if abs (delta_gc - delta_counter) > tol then begin
    log "GC statistics do not match runtime counter values for %s: %d != %d"
      (runtime_counter_name counter_expected)
      delta_gc delta_counter;
  end;
  if delta_gc < expected_value_geq then begin
    log "[GC statistic for %s %d < %d"
      (runtime_counter_name counter_expected) delta_gc expected_value_geq;
  end;
  if delta_counter < expected_value_geq then begin
    log "Runtime counter values for %s too low: %d < %d"
      (runtime_counter_name counter_expected)
      delta_counter expected_value_geq;
  end;
  if not !bad then Format.printf "OK@."


let major_slice () =
  let _ : int = Gc.major_slice 0 in ()

let run_in_single_domain ~after f ()  =
  let domain = Domain.spawn (fun () ->
    Fun.protect ~finally:after f) in
  Domain.join domain

let run_with_domain ~domain_workload ~before ~after f =
  let domain = Domain.spawn domain_workload in
  let finally () = Domain.join domain in
  Fun.protect ~finally @@ fun () ->
  before ();
  Fun.protect ~finally:after f

let run_with_spin_domain ~do_major_slice f () =
  let run = Atomic.make true
  and domain_running = Atomic.make false
  in
  let before () =
    (* wait for domain to get spawned and begin running *)
    while not (Atomic.get domain_running) do
      Domain.cpu_relax ()
    done
  in
  let after () = Atomic.set run false in
  let domain_workload () =
    Atomic.set domain_running true;
    while Atomic.get run do Domain.cpu_relax () done;
    if do_major_slice then major_slice ()
  in
  run_with_domain ~domain_workload ~after ~before f

let run_and_compare_scenarios f counter_expected counter_type
observe_gc expected_value_geq=
  let scenario ~__LINE__ name f =
    Format.printf "%s: @?" name;
    run_and_compare_test ~__LINE__ f counter_expected counter_type observe_gc expected_value_geq
  in
  scenario ~__LINE__ "Just the main domain" f;

  scenario ~__LINE__ "Run in single domain with full GC, main domain idle"
    (run_in_single_domain ~after:Gc.full_major f);

  scenario ~__LINE__ "Run in single domain with major slice, main domain idle"
    (run_in_single_domain ~after:major_slice f);

  scenario ~__LINE__ "Main domain, with spinning extra domain and major slice"
    (run_with_spin_domain ~do_major_slice:true f);

  scenario ~__LINE__ "Main domain, with spinning extra domain and no explicit major slice"
    (run_with_spin_domain ~do_major_slice:false f)



let () =
    let counter = EV_C_MAJOR_ALLOCATED_WORDS in
    run_and_compare_scenarios ignore counter Additive (fun t -> t.major_words |> int_of_float) 0
