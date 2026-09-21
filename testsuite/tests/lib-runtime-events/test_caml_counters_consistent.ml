(* TEST
 include runtime_events;
*)
open Runtime_events

let make () = Array.make 128 0

(* we assume these will be small enough not to overflow
   during the test *)
let minor_words = make ()
let minor_bytes = make ()

let promoted_words = make ()
let promoted_bytes = make ()

let major_words = make ()

let heap_words = make ()
let live_words = make ()
let pool_words = make ()
let pool_live_words = make ()
let large_words = make ()
let live_blocks = make ()
let pool_live_blocks = make ()
let large_blocks = make ()
let free_words = make ()
let fragments = make ()
let compactions = make ()

let sum a = Array.fold_left (+) 0 a

let check_int ?(tol=0) name counter_ref stat =
  let actual = sum counter_ref
  and expected = stat in
  if abs (actual - expected) > tol then begin
    Printf.eprintf "%s: counter %d != stat %d\n" name actual expected;
    1
  end else 0

let check ?tol name counter_ref stat =
  check_int ?tol name counter_ref (stat |> Float.round |> Float.to_int)

let check_words_bytes name counter_words counter_bytes =
  let actual = sum counter_bytes
  and expected = sum counter_words * Sys.word_size / 8 in
  if actual != expected then begin
    Printf.eprintf "%s words vs bytes: %d != %d\n" name actual expected;
    1
  end else 0

let[@inline] inc i target v =
  target.(i) <- target.(i) + v

let runtime_counter i _ts name value =
  match name with
  | EV_C_MINOR_ALLOCATED_WORDS ->
      inc i minor_words value
  | EV_C_MINOR_ALLOCATED ->
      inc i minor_bytes value
  | EV_C_MINOR_PROMOTED_WORDS ->
      inc i promoted_words value
  | EV_C_MINOR_PROMOTED ->
      inc i promoted_bytes value
  | EV_C_MAJOR_ALLOCATED_WORDS ->
      inc i major_words value
  | EV_C_MAJOR_HEAP_WORDS ->
      heap_words.(0) <- value (* not cumulative! *)
  | EV_C_MAJOR_HEAP_POOL_LIVE_WORDS ->
      pool_live_words.(0) <- value
  | EV_C_MAJOR_HEAP_LARGE_WORDS ->
      large_words.(0) <- value
  | EV_C_MAJOR_HEAP_POOL_LIVE_BLOCKS ->
      pool_live_blocks.(0) <- value
  | EV_C_MAJOR_HEAP_LARGE_BLOCKS ->
      large_blocks.(0) <- value
  | EV_C_MAJOR_HEAP_POOL_FRAG_WORDS ->
      fragments.(0) <- value
  | EV_C_MAJOR_HEAP_POOL_WORDS ->
      pool_words.(0) <- value
  | _ -> ()

let update () =
  (* see caml_gc_quick_stat *)
  live_words.(0) <- sum pool_live_words + sum large_words;
  live_blocks.(0) <- sum pool_live_blocks + sum large_blocks;
  free_words.(0) <- sum pool_words - sum pool_live_words - sum fragments;
  (* this does not match EV_MAJOR_HEAP_WORDS exactly, calculate as in gc_ctrl.c *)
  heap_words.(0) <- sum pool_words + sum large_words

let check_stats ~tol t =
  update ();
  check ~tol "minor_words" minor_words t.Gc.minor_words +
  check_words_bytes "minor_bytes" minor_words minor_bytes +
  check ~tol "promoted_words" promoted_words t.Gc.promoted_words +
  check_words_bytes "promoted_bytes" promoted_words promoted_bytes +
  check ~tol "major_words" major_words t.Gc.major_words +
  check_int "heap_words" heap_words t.Gc.heap_words +
  check_int "heap_chunks" (make ()) t.Gc.heap_chunks +
  check_int "live_words" live_words t.Gc.live_words +
  check_int "live_blocks" live_blocks t.Gc.live_blocks +
  check_int "free_words" free_words t.Gc.free_words +
  check_int "free_blocks" (make ()) t.Gc.free_blocks +
  check_int "largest_free" (make ()) t.Gc.largest_free +
  check_int "fragments" fragments t.Gc.fragments

let lost_events _ _ =
  prerr_endline "EVENTS LOST"

let callbacks = Callbacks.create ~runtime_counter ~lost_events ()

type 'a tree = Empty | Node of 'a tree * 'a tree

let alloc_workload () =
  Array.init 10000 (fun _ -> String.make 100 'x') |>ignore

let domain_workload () =
  (* Multi domain *)
  let domains = Array.init 2 (fun _ -> Domain.spawn alloc_workload)
  in
  Array.iter Domain.join domains

let () =
    start ();
    let cursor = create_cursor None in
    let check_consistency f =
      f ();
      Gc.full_major ();
      Gc.minor ();
      let t = Gc.quick_stat () in
      Gc.minor ();
      while read_poll cursor callbacks None > 0 do ()
      done;
      let tol = t |> Obj.repr |> Obj.reachable_words in
      check_stats ~tol t
    in
    let errors =
      let a = check_consistency ignore in
      (* run the simple one first, do not depend on eval order *)
      let () = Sys.opaque_identity () in
      let b = check_consistency domain_workload in
      a + b
    in
    if errors > 0 then begin
      Printf.eprintf "FAIL: %d mismatches\n" errors;
      exit 1
    end
