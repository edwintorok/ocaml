(* TEST
 include runtime_events;
 flags="-g";
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

type User.tag += Allocating_words
let allocating_words = User.register "allocating_words" Srcline Type.int
let allocating_words value = User.write allocating_words value

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


  let dump counter counter_type history =
    (* avoid flooding the output with unrelated events from the allocations done by poll:
       pause
    *)
    pause ();
    Format.printf "@.";
    Format.eprintf "@.%s@." (String.make 78 '=');
    Format.eprintf "@[<v>";
    poll cursor callbacks;
    Format.eprintf "@[Counter %s history:@ %a@]@," (runtime_counter_name counter)
      Format.(pp_print_array ~pp_sep:Format.pp_print_space pp_print_int) history;
    Format.eprintf "@]@.";
    resume ();
    Gc.minor ();
    drop ()

end

let lost_events_fail domain_id lost_words=
  Format.asprintf "[% 3d] LOST %d words in events" domain_id lost_words
  |> failwith

type counter_type = Additive | Absolute

let run_and_compare ~__LINE__ f counter_expected counter_type observe_gc =
  let counter_value = ref 0 in
  let counter_history = Array.make 10_000 0 in
  let history = ref 0 in
  let runtime_counter domain_id timestamp counter value =
    if counter = counter_expected then begin
      if counter_type = Additive then
        counter_value := !counter_value + value
      else
        counter_value := value;
      counter_history.(!history) <- value;
      incr history
    end
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
    (* ensure stats are up-to-date for [quick_stat] *)
    Gc.minor ();
    let gc = Gc.quick_stat () |> observe_gc in
    (* polling allocates int64 timestamps, so run final one after *)
    poll cursor callbacks;
    let counter = !counter_value in
    (* this may allocate (when processed), so run after *)
    gc_observed gc;
    gc, counter
  in
  (* this may complain about dropped events, that is expected,
     we haven't been watching the ring from the beginning *)
  poll cursor Dump.noop;
  history := 0;

  let baseline_gc, baseline_counter = observe () in
  (* don't drop events here, the additive counters would get out of sync *)
  with_workload f;
  let after_gc, after_counter = observe () in

  let delta_gc = after_gc - baseline_gc
  and delta_counter = after_counter - baseline_counter in
  delta_gc, delta_counter, Array.sub counter_history 0 !history |> Array.to_seq |> Seq.filter (fun x -> x > 0) |> Array.of_seq

let gc_stat_words = Gc.quick_stat () |> Obj.repr |> Obj.reachable_words

let run_and_compare_test ~__LINE__ f counter_expected counter_type observe_gc expected_value_geq=
  let delta_gc0, delta_counter0, history0 = run_and_compare ~__LINE__:Stdlib.__LINE__ ignore counter_expected counter_type observe_gc in
  let tol = abs (delta_gc0 - delta_counter0) in
  if tol > delta_gc0 then begin
    Dump.dump counter_expected counter_type history0;
    Format.eprintf "[!] Runtime counter value %s on no-op workload: %+d, GC counter value: %+d@."
      (runtime_counter_name counter_expected)
      delta_counter0 delta_gc0;
  end;
  (* poll runs after quick_stat, so it may see some words promoted *)
  let tol = max gc_stat_words tol in (* don't be too strict *)
  let delta_gc, delta_counter, history = run_and_compare ~__LINE__ f counter_expected counter_type observe_gc in
  let bad = ref false in
  let log fmt =
    bad := true;
    Dump.dump counter_expected counter_type history;
    let finish ppf = Format.fprintf ppf "@." in
    Format.eprintf "[!] ";
    Format.kfprintf finish Format.err_formatter fmt
  in
  if abs (delta_gc - delta_counter) > tol then begin
    log "GC statistics do not match runtime counter values for %s: %d != %d"
      (runtime_counter_name counter_expected)
      delta_gc delta_counter;
  end;
  if delta_gc - delta_gc0 < expected_value_geq then begin
    log "[GC statistic for %s %d < %d"
      (runtime_counter_name counter_expected) delta_gc expected_value_geq;
  end;
  if delta_counter - delta_counter0 < expected_value_geq then begin
    log "Runtime counter values for %s too low: %d - %d < %d"
      (runtime_counter_name counter_expected)
      delta_counter delta_counter0 expected_value_geq;
  end;
  if not !bad then Format.printf "OK@."


let major_slice () =
  let _ : int = Gc.major_slice 0 in ()

let run_in_single_domain ~after f  =
  (* TODO: use wrapper that spawns and waits *)
  let in_domain () = Fun.protect ~finally:after f in
  fun () ->
  let domain = Domain.spawn in_domain in
  Domain.join domain

let run_with_domain ~domain_workload ~before ~after f =
  let body () = before (); Fun.protect ~finally:after f in
  fun () ->
  let domain = Domain.spawn domain_workload in
  let finally () = Domain.join domain in
  Fun.protect ~finally body

let run_with_spin_domain ~do_major_slice f =
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

let run_domains ~after n f =
  let body () = Fun.protect ~finally:after f in
  let in_domain _ = Domain.spawn body in
  fun () ->
  let domains = Array.init n in_domain in
  Array.iter Domain.join domains

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
    (run_with_spin_domain ~do_major_slice:false f);

  [2; 8] |> List.iter @@ fun ndomains ->
  let name s = Printf.sprintf "%d domains, %s" ndomains s in
  scenario ~__LINE__ (name "no explicit major slice")
    (run_domains ndomains ~after:ignore f);

  scenario ~__LINE__ (name "with explicit major slice")
    (run_domains ndomains ~after:ignore f);

  scenario ~__LINE__ (name "with full major GC")
    (run_domains ndomains ~after:Gc.full_major f)



(* should match Max_young_wosize *)
let max_young_wosize = 256
let word_size_bytes = Sys.word_size / 8

let alloc_words words =
  allocating_words words;
  (* do not use array allocations, because they might also trigger a minor GC *)
  String.make ((words - 2) * word_size_bytes) ' '

(* use a value that would distinguishable in the debug output *)
let distinguishable_large = 123456
let () =
  (* ensure this is not allocated in the minor heap, or pools, but as a large allocation *)
  assert (distinguishable_large > 2*max_young_wosize)

let distinguishable_small = 123
let () =
  (* ensure this is not allocated in the minor heap, or pools, but as a large allocation *)
  assert (distinguishable_small < max_young_wosize)

let () =
  Printexc.record_backtrace true;
    let counter = EV_C_MAJOR_ALLOCATED_WORDS in
    run_and_compare_scenarios ignore counter Additive (fun t -> t.major_words |> int_of_float) 0;

    let run_alloc ?(promote=false) count n =
      Format.printf "@.Allocation size: %d, count: %d@." n count;
      run_and_compare_scenarios (fun () ->
        (* ensure that we see the exact value [n] promoted,
           and not summed with previous values in the minor heap
         *)
        if promote then Gc.minor ();
        let s = Array.init count (fun _ -> alloc_words n) in
        if promote then Gc.minor ();
        (* keep [s] alive across Gc.minor to ensure promotion *)
        Sys.opaque_identity s |> ignore
      ) counter Additive (fun t -> t.major_words |> int_of_float) n
    in

    run_alloc 1 distinguishable_large;

    run_alloc ~promote:true 1 distinguishable_small;


