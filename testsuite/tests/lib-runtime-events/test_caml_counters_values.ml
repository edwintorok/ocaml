(* TEST
 include runtime_events;
 flags="-g";
*)
open Runtime_events

module Events = struct
  type User.tag += Workload

  let workload = User.register "workload" Workload Type.span

  let[@inline] emit_workload_begin () = User.write workload Type.Begin

  let[@inline] emit_workload_end () = User.write workload Type.End

  type User.tag += Srcline

  let srcline = User.register "srcline" Srcline Type.int

  let[@inline] emit_line ~__LINE__ = User.write srcline __LINE__

  type User.tag += Message

  let str =
    let encode buf str =
      let n = min 1024 (String.length str) in
      Bytes.blit_string str 0 buf 0 n ;
      n
    and decode buf n = Bytes.sub_string buf 0 n in
    Type.register ~encode ~decode

  let message = User.register "message" Message str

  let[@inline] emit_message str = User.write message str

  type User.tag += Allocating_words

  let allocating_words = User.register "allocating_words" Srcline Type.int

  let[@inline] emit_allocating_words value = User.write allocating_words value

  let alloc_words = User.register "alloc_words" Workload Type.span

  let[@inline] emit_alloc_words_begin () = User.write workload Type.Begin

  let[@inline] emit_alloc_words_end () = User.write workload Type.End

  type User.tag += Gc_stat_observed

  let gc_stat_observed =
    User.register "gc_stat_observed" Gc_stat_observed Type.int

  let[@inline] emit_gc_observed value = User.write gc_stat_observed value
end

open Events

let t0 = Timestamp.get_current () |> Timestamp.to_int64 |> Int64.to_int

let with_workload f =
  emit_workload_begin () ;
  Fun.protect ~finally:emit_workload_end f

(* To avoid flooding the runtime event ring,
   we only unpause emitting events when running the actual workload.
   Counter measurements are always done relative to a baseline,
   so the missed updates won't cause measured counter values to drift.
 *)
let () = start () ; pause ()

let poll cursor callbacks =
  while read_poll cursor callbacks None > 0 do
    ()
  done

module Drop = struct
  let noop = Callbacks.create ()

  let drop cursor = poll cursor noop
end

module Dump = struct
  (* Separate cursor, used only when debugging a failure,
     to see the event history *)
  let cursor = create_cursor None

  let pp_timestamp ppf ts =
    let dt =
      1e-9 *. ((ts |> Timestamp.to_int64 |> Int64.to_int) - t0 |> float_of_int)
    in
    Format.fprintf ppf "%.9f s" dt

  let indent = Array.make 128 0

  let header domain_id timestamp =
    Format.eprintf "[%a][% 3d]%*s " pp_timestamp timestamp domain_id
      indent.(domain_id) ""

  let add_indent domain_id v = indent.(domain_id) <- indent.(domain_id) + v

  let runtime_phase domain_id timestamp phase kind =
    header domain_id timestamp ;
    Format.eprintf "%s %s@," kind (runtime_phase_name phase)

  let runtime_begin domain_id timestamp phase =
    runtime_phase domain_id timestamp phase ">" ;
    add_indent domain_id 1

  let runtime_end domain_id timestamp phase =
    add_indent domain_id (-1) ;
    runtime_phase domain_id timestamp phase "<"

  let runtime_counter domain_id timestamp counter value =
    header domain_id timestamp ;
    Format.eprintf "%37s =% 19d@," (runtime_counter_name counter) value

  let lifecycle domain_id timestamp lifecycle arg =
    header domain_id timestamp ;
    Format.eprintf "%s %a@," (lifecycle_name lifecycle)
      Format.(pp_print_option Format.pp_print_int)
      arg

  let lost_events domain_id lost_words =
    header domain_id (Timestamp.get_current ()) ;
    Format.eprintf "LOST EVENTS: %d words@," lost_words

  let user_span domain_id timestamp user value =
    let c = if value = Type.Begin then '>' else '<' in
    if value = Type.End then add_indent domain_id (-1) ;
    header domain_id timestamp ;
    Format.eprintf "%c %s@," c (User.name user) ;
    if value = Type.Begin then add_indent domain_id 1

  let user_int domain_id timestamp user value =
    header domain_id timestamp ;
    Format.eprintf "%s=%d@," (User.name user) value

  let callbacks =
    Callbacks.create ~runtime_begin ~runtime_end ~runtime_counter ~lifecycle
      ~lost_events ()
    |> Callbacks.add_user_event Type.span user_span
    |> Callbacks.add_user_event Type.int user_int

  let drop () = Drop.drop cursor

  let dump counter _counter_type history =
    (* avoid flooding the output with unrelated events from the allocations done by poll:
       pause
    *)
    Format.printf "@." ;
    Format.eprintf "@.%s@." (String.make 78 '=') ;
    Format.eprintf "@[<v>" ;
    poll cursor callbacks ;
    Format.eprintf "@[Counter %s history:@ %a@]@,"
      (runtime_counter_name counter)
      Format.(pp_print_array ~pp_sep:Format.pp_print_space pp_print_int)
      history ;
    Format.eprintf "@]@."
end

let lost_events_fail domain_id lost_words =
  Format.asprintf "[% 3d] LOST %d words in events" domain_id lost_words
  |> failwith

type counter_type = Additive | Absolute

let run_and_compare ~__LINE__ f counter_expected counter_type observe_gc =
  let counter_value = ref 0 in
  let counter_history = Array.make 10_000 0 in
  let history = ref 0 in
  let runtime_counter _domain_id _timestamp counter value =
    if counter = counter_expected then begin
      if counter_type = Additive then counter_value := !counter_value + value
      else counter_value := value ;
      counter_history.(!history) <- value ;
      incr history
    end
  in
  let callbacks =
    Callbacks.create ~runtime_counter ~lost_events:lost_events_fail ()
  in
  let cursor = create_cursor None in
  let finally () = free_cursor cursor in
  Fun.protect ~finally
  @@ fun () ->
  let observe () =
    (* major GC counters are only emitted if a major slice occurred *)
    let _ : int = Gc.major_slice 0 in
    (* ensure stats are up-to-date for [quick_stat] *)
    Gc.minor () ;
    let gc = Gc.quick_stat () |> observe_gc in
    (* polling allocates int64 timestamps, so run final one after *)
    poll cursor callbacks ;
    let counter = !counter_value in
    (* this may allocate (when processed), so run after *)
    emit_gc_observed gc ; (gc, counter)
  in
  (* start fresh, but don't yet count these *)
  Gc.compact () ;
  (* The previous events have either been reported already on a failure,
     or not needed on success.
     Either way start with empty events.
   *)
  Dump.drop () ;
  (* this may complain about dropped events, that is expected,
     we haven't been watching the ring from the beginning *)
  Drop.drop cursor ;
  Gc.minor ();
  history := 0 ;
  (* enable runtime events just during the observations *)
  resume () ;
  emit_line ~__LINE__ ;
  let baseline_gc, baseline_counter = observe () in
  (* don't drop events here, the additive counters would get out of sync *)
  with_workload f ;
  let after_gc, after_counter = observe () in
  emit_line ~__LINE__ ;
  pause () ;
  let delta_gc = after_gc - baseline_gc
  and delta_counter = after_counter - baseline_counter
  and history =
    Array.sub counter_history 0 !history
    |> Array.to_seq
    |> Seq.filter (fun x -> x > 0)
    |> Array.of_seq
  in
  (delta_gc, delta_counter, history)

let gc_stat_words = Gc.quick_stat () |> Obj.repr |> Obj.reachable_words

let run_and_compare_test ~__LINE__ f counter_expected counter_type observe_gc
    expected_value_geq =
  let delta_gc0, delta_counter0, history0 =
    run_and_compare ~__LINE__:Stdlib.__LINE__ ignore counter_expected
      counter_type observe_gc
  in
  let tol = abs (delta_gc0 - delta_counter0) in
  let bad = ref false in
  let log fmt =
    bad := true ;
    let finish ppf = Format.fprintf ppf "@." in
    Format.eprintf "[!] " ;
    Format.kfprintf finish Format.err_formatter fmt
  in
  if tol > delta_gc0 then begin
    Dump.dump counter_expected counter_type history0 ;
    log "Runtime counter value %s on no-op workload: %+d, GC counter value: %+d"
      (runtime_counter_name counter_expected)
      delta_counter0 delta_gc0
  end ;
  (* poll runs after quick_stat, so it may see some words promoted *)
  let tol = max gc_stat_words tol in
  (* don't be too strict *)
  let delta_gc, delta_counter, history =
    run_and_compare ~__LINE__ f counter_expected counter_type observe_gc
  in
  let log fmt =
    Dump.dump counter_expected counter_type history ;
    log fmt
  in
  if abs (delta_gc - delta_counter) > tol then begin
    log "GC statistics do not match runtime counter values for %s: %d != %d"
      (runtime_counter_name counter_expected)
      delta_gc delta_counter
  end ;
  if delta_gc - delta_gc0 < expected_value_geq then begin
    log "GC statistic for %s %d - %d < %d"
      (runtime_counter_name counter_expected)
      delta_gc delta_gc0 expected_value_geq
  end ;
  if delta_counter - delta_counter0 < expected_value_geq then begin
    log "Runtime counter values for %s too low: %d - %d < %d"
      (runtime_counter_name counter_expected)
      delta_counter delta_counter0 expected_value_geq
  end ;
  if not !bad then Format.printf "OK@."

let major_slice () =
  let _ : int = Gc.major_slice 0 in
  ()

let run_domains ~main_workload ~domain_workload ndomains =
  let barrier_reached = Atomic.make 0 in
  let barrier () =
    Atomic.incr barrier_reached ;
    (* Wait until every workload, including the main one has reached this point.
       This allows us to perform the allocations in this function outside of the region
       where runtime events are turned on, so they don't randomly interfere.
     *)
    while Atomic.get barrier_reached <> ndomains + 1 do
      Domain.cpu_relax ()
    done
  in
  let worker () =
    barrier () ;
    with_workload domain_workload
  in
  let domains = Array.init ndomains (fun _ -> Domain.spawn worker) in
  let finally () = Array.iter Domain.join domains in
  let body () =
    barrier () ;
    with_workload main_workload
  in
  (* Create all necessary closures before this to reduce unrelated allocations
     inside the workload *)
  fun () -> Fun.protect ~finally body

let run_in_single_domain ~after f n =
  assert (n = 1) ;
  let domain_workload () = Fun.protect ~finally:after f in
  run_domains ~main_workload:ignore ~domain_workload n

let run_with_spin_domain ~after f n =
  assert (n = 1) ;
  let run = Atomic.make true in
  let finally () = Atomic.set run false in
  let main_workload () =
    Fun.protect ~finally f
  in
  let domain_workload () =
    while Atomic.get run do
      Domain.cpu_relax ()
    done ;
    after ()
  in
  run_domains ~main_workload ~domain_workload n

let run_domains ~after f n =
  let domain_workload () = Fun.protect ~finally:after f in
  run_domains ~main_workload:ignore ~domain_workload n

let run_and_compare_scenarios f counter_expected counter_type observe_gc
    expected_value_geq =
  let scenario n ~__LINE__ name f =
    Format.printf "%s (%d domains): @?" name n ;
    run_and_compare_test ~__LINE__ (f n) counter_expected counter_type
      observe_gc (n * expected_value_geq)
  in
  scenario 1 ~__LINE__ "Just the main domain" (fun _ -> f) ;
  scenario 1 ~__LINE__ "Run in single domain with full GC, main domain idle"
    (run_in_single_domain ~after:Gc.full_major f) ;
  scenario 1 ~__LINE__ "Run in single domain with major slice, main domain idle"
    (run_in_single_domain ~after:major_slice f) ;
  scenario 1 ~__LINE__ "Main domain, with spinning extra domain and major slice"
    (run_with_spin_domain ~after:major_slice f) ;
  scenario 1 ~__LINE__
    "Main domain, with spinning extra domain and no explicit major slice"
    (run_with_spin_domain ~after:major_slice f) ;
  [2; 8]
  |> List.iter
     @@ fun ndomains ->
     let name s = Printf.sprintf "%d domains, %s" ndomains s in
     scenario ndomains ~__LINE__
       (name "no explicit major slice")
       (run_domains ~after:ignore f) ;
     scenario ndomains ~__LINE__
       (name "with explicit major slice")
       (run_domains ~after:ignore f) ;
     scenario ndomains ~__LINE__
       (name "with full major GC")
       (run_domains ~after:Gc.full_major f)

(* should match Max_young_wosize *)
let max_young_wosize = 256

let word_size_bytes = Sys.word_size / 8

let alloc_words words =
  emit_alloc_words_begin () ;
  emit_allocating_words words ;
  (* do not use array allocations, because they might also trigger a minor GC *)
  let s = String.make ((words - 2) * word_size_bytes) ' ' in
  emit_alloc_words_end () ; s

(* use a value that would distinguishable in the debug output *)
let distinguishable_large = 123456

(* calibrate offset, 1 or 3 words depending whether small or large: ask the runtime *)
let calibrate n =
  let actual = alloc_words n |> Obj.repr |> Obj.reachable_words in
  n + (n - actual)

let distinguishable_large = calibrate distinguishable_large

let () =
  (* ensure this is not allocated in the minor heap, or pools, but as a large allocation *)
  assert (distinguishable_large > 2 * max_young_wosize)

let distinguishable_small = 123
let distinguishable_small = calibrate distinguishable_small

let () =
  (* ensure this is not allocated in the minor heap, or pools, but as a large allocation *)
  assert (distinguishable_small < max_young_wosize / 2)

let () =
  (* we only print backtraces on errors, so doesn't affect reproducibility on success. *)
  Printexc.record_backtrace true ;
  let counter = EV_C_MAJOR_ALLOCATED_WORDS in
  run_and_compare_scenarios ignore counter Additive
    (fun t -> t.major_words |> int_of_float)
    0 ;
  let run_alloc ?(promote = false) count n =
    Format.printf "@.Allocation size: %d, count: %d@." n count ;
    run_and_compare_scenarios
      (fun () ->
        (* ensure that we see the exact value [n] promoted,
           and not summed with previous values in the minor heap
         *)
        if promote then Gc.minor () ;
        let s = Array.init count (fun _ -> alloc_words n) in
        if promote then Gc.minor () ;
        (* keep [s] alive across Gc.minor to ensure promotion *)
        Sys.opaque_identity s |> ignore )
      counter Additive
      (fun t -> t.major_words |> int_of_float)
      n
  in
  run_alloc 1 distinguishable_large ;
  run_alloc ~promote:true 1 distinguishable_small
