(* TEST
 include runtime_events;
 flags="-g";
*)
open Runtime_events

(** [poll_all cursor callbacks] reads all available events from the runtime events ring.
    Processing events may allocate (e.g. [int64] timestamps, user event type cache)
 *)
let poll_all cursor callbacks =
  while read_poll cursor callbacks None > 0 do () done

type history =
{ values: int array
; domains: int array
; mutable idx: int
}

let max_events = 1000
let history =
{ values = Array.make max_events 0
; domains = Array.make max_events 0
; idx = 0
}

let get t =
  Array.sub t.values 0 t.idx

let sum t =
  t |> get |> Array.fold_left (+) 0

let reset () =
  Array.fill history.values 0 (Array.length history.values) 0;
  Array.fill history.domains 0 (Array.length history.domains) 0;
  history.idx <- 0

let expected_counter = EV_C_MAJOR_ALLOCATED_WORDS

let runtime_counter domain_id _ counter value =
  if counter = expected_counter && value > 0 then begin
    history.domains.(history.idx) <- domain_id;
    history.values.(history.idx) <- value;
    history.idx <- history.idx + 1;
    if history.idx >= max_events then begin
      prerr_endline "Counter history overflow";
      history.idx <- 0
    end;
  end

let dump_history () =
  Format.eprintf "@[<v1>Counter %s history:"
    (runtime_counter_name expected_counter);
  for i = 0 to history.idx-1 do
    Format.eprintf "@,domain %d: %d" history.domains.(i) history.values.(i)
  done;
  Format.eprintf "@]@."

let callbacks = Callbacks.create ~runtime_counter ()

let amount = 1234567

let alloc () =
  String.make (amount * Sys.word_size / 8) ' '
  |> Sys.opaque_identity

let run_alloc () =
  let _ : string = alloc () in
  ()

let run_alloc_pause_resume () =
  pause ();
  let _ : string = alloc () in
  resume ()

let run_in_domain () =
  let domain = Domain.spawn run_alloc in
  Domain.join domain

let expected = alloc () |> Obj.repr |> Obj.reachable_words

let workload f =
  resume ();
  let () = f () in
  (* some counters are only emitted by the major GC *)
  Gc.full_major ();
  pause ()

let measure name cursor f =
  (* start fresh *)
  Gc.compact ();
  reset ();
  workload f;
  poll_all cursor callbacks;
  let actual = sum history in
  (* could be more due to other small allocations, but it shouldn't be less:
     if it is less it means we've missed the allocation completely
  *)
  Format.eprintf "Testing %s: @?" name;
  if actual < expected then begin
    Format.eprintf "%s %d < expected %d@." (runtime_counter_name expected_counter) actual expected;
    dump_history ()
  end else Format.eprintf "OK@."

let () =
  assert (expected >= amount);
  (* start and immediately pause: only emit events in the measured region *)
  start (); pause ();
  let cursor = create_cursor None in
  let finally () = free_cursor cursor in
  Fun.protect ~finally @@ fun () ->
  measure "alloc" cursor run_alloc;
  measure "run_in_domain" cursor run_in_domain;
  measure "pause+alloc+resume" cursor run_alloc_pause_resume
