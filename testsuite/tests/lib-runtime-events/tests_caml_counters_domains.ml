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
; last: int array
; domains: int array
; timestamps: int64 array
; mutable idx: int
}

let max_domains = 128
let global = max_domains
let max_events = 1000
let history =
{ values = Array.make max_events 0
; last = Array.make (max_domains + 1) 0
; domains = Array.make max_events 0
; timestamps = Array.make max_events 0L
; idx = 0
}

let get t =
  Array.sub t.values 0 t.idx

let reset () =
  Array.fill history.values 0 (Array.length history.values) 0;
  Array.fill history.last 0 (Array.length history.last) 0;
  Array.fill history.domains 0 (Array.length history.domains) 0;
  history.idx <- 0

let expected_counter = EV_C_MAJOR_HEAP_WORDS, EV_C_GLOBAL_MAJOR_HEAP_WORDS


let runtime_counter domain_id ts counter value =
  let local_counter, global_counter = expected_counter in
  if (counter = local_counter || counter = global_counter) && value > 0 then begin
    let ts = Runtime_events.Timestamp.to_int64 ts in
    if history.idx = 0 ||
      (value <> history.values.(history.idx-1) &&
       ts > history.timestamps.(history.idx-1)) then begin
      let domain_id = if counter = local_counter then domain_id else global in
      history.domains.(history.idx) <- domain_id;
      history.values.(history.idx) <- value;
      history.timestamps.(history.idx) <- ts;
      history.idx <- history.idx + 1;
      history.last.(domain_id) <- value;
      if history.idx >= max_events then begin
        prerr_endline "Counter history overflow";
        history.idx <- 0
      end;
    end
  end

let dump_history () =
  let e1, e2 = expected_counter in
  Format.eprintf "@[<v1>Counter %s and %s history:"
    (runtime_counter_name e1)
    (runtime_counter_name e2);
  for i = 0 to history.idx-1 do
    Format.eprintf "@,%Ld ns, domain %d: %d" history.timestamps.(i) history.domains.(i) history.values.(i)
  done;
  Format.eprintf "@]@."

let callbacks = Callbacks.create ~runtime_counter ()

let amount = 1234567
let count = 3

let alloc () =
  Array.init count (fun _ -> String.make (amount * Sys.word_size / 8) ' ')
  |> Sys.opaque_identity

let run_alloc _ =
  let s = alloc () in
  Gc.minor ();
  Sys.opaque_identity s

let run_alloc_pause_resume _ =
  pause ();
  let s = alloc () in
  resume ();
  s

let run_with_domain n  =
  let domains = Array.init n (fun _ -> Domain.spawn Gc.full_major) in
  let s = run_alloc () in
  Array.iter Domain.join domains;
  s

let run_in_domain n  =
  let domains = Array.init n (fun _ -> Domain.spawn run_alloc) in
  let s = run_alloc () in
  let a = Array.map Domain.join domains in
  (s, a)

let expected = alloc () |> Obj.repr |> Obj.reachable_words

let workload f n =
  resume ();
  let s = f n in
  (* some counters are only emitted by the major GC.
     Although on program exit we won't get a full major,
     so call just the slice update.
   *)
  let _ : int = Gc.major_slice 0 in
  pause ();
  (* keep value live across major GC *)
  let _ = Sys.opaque_identity s in
  ()

let measure name cursor f extra =
  (* start fresh *)
  Gc.compact ();
  reset ();
  workload f extra;
  poll_all cursor callbacks;
  let actual = Array.fold_left (+) 0 history.last in
  (* could be more due to other small allocations, but it shouldn't be less:
     if it is less it means we've missed the allocation completely
  *)
  Format.eprintf "Testing %s: @?" name;
  let expected = (1 + extra) * expected in
  let local, global = expected_counter in
  if actual < expected then begin
    Format.eprintf "%s and %s %d < expected %d@." (runtime_counter_name local) (runtime_counter_name global) actual expected;
    dump_history ()
  end else Format.eprintf "OK@."

let () =
  assert (expected >= amount);
  (* start and immediately pause: only emit events in the measured region *)
  start (); pause ();
  let cursor = create_cursor None in
  let finally () = free_cursor cursor in
  Fun.protect ~finally @@ fun () ->
  measure "alloc" cursor run_alloc 0;
  measure "run_with_domain" cursor run_with_domain 0;
  measure "run_in_domain" cursor run_in_domain 2;
  measure "pause+alloc+resume" cursor run_alloc_pause_resume 0
