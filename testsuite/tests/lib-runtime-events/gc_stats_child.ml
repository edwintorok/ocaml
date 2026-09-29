(* Child program that does allocation work.
   Used by test_gc_stats_match.ml.

   With OCAMLRUNPARAM=v=0x400, the runtime prints GC stats to stderr at exit.
   With OCAML_RUNTIME_EVENTS_START=1, runtime events are enabled from startup.
   The parent compares the v=0x400 stats with runtime event counters. *)

let run () =
  (* Do allocation that triggers multiple minor GCs *)
  let r = ref [] in
  for _ = 1 to 100 do
    for i = 1 to 1000 do
      r := (Sys.opaque_identity (ref i)) :: !r
    done;
    Gc.minor ()
  done;
  !r

let () =
  let extra_domains = Sys.argv.(1) |> int_of_string in

  let domains = List.init extra_domains (fun _ -> Domain.spawn run) in

  let r = run () in
  let alive = r :: List.map Domain.join domains in

  (* Do a major GC *)
  Gc.full_major ();

  (* Keep data alive until exit *)
  let _ = Sys.opaque_identity alive in
  ()
