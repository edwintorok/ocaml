(* TEST
 include runtime_events;
 include unix;
 set OCAML_RUNTIME_EVENTS_PRESERVE = "1";
 libunix;
 {
   bytecode;
 }{
   native;
 }
*)

  let with_ring ring_file f =
    let fd = Unix.openfile ring_file [Unix.O_RDWR] 0 in
    let size = Int64.to_int Unix.LargeFile.((fstat fd).st_size) / 8 in
    let map = Unix.map_file fd Bigarray.int64 Bigarray.c_layout false [| size |] in
    let ba = Bigarray.reshape_1 map size in
    (* see runtime_events_metadata_header *)
    let version = ba.{0} in
    assert (version = 1L);
    (* this needs to be updated if on-disk layout changes *)
    let data_offset = ba.{6} in
    let buf = Bytes.create 8 in
    let write_event_header is_runtime event_type event_id event_length =
      let (<<:) i n = Int64.(shift_left (of_int i) n) and (|:) = Int64.logor in
      (* see runtime_events.h *)
      let event_header =
        (event_length <<: 54) |:
        (is_runtime <<: 53) |:
        (event_type <<: 49) |:
        (event_id <<: 36)
      in
      Bytes.set_int64_ne buf 0 event_header;
      let (_:int64) = Unix.LargeFile.lseek fd data_offset Unix.SEEK_SET in
      let n = Unix.write fd buf 0 (Bytes.length buf) in
      assert (n = Bytes.length buf)
    in
    f write_event_header;
    Unix.close fd

  (* this tests the preservation of ring buffers after termination *)

  let () =
    (* start runtime_events now to avoid a race *)
    let parent_cwd = Sys.getcwd () in
    let child_pid = Unix.fork () in
    if child_pid == 0 then begin
      (* we are in the child, so start Runtime_events *)
      Runtime_events.start ();
      (* this creates a ring buffer. Now exit. *)
    end else begin
      (* now wait for our child to finish *)
      Unix.wait () |> ignore;
      (* child has finished. We now have a valid ring *)
      let ring_file =
          Filename.concat parent_cwd (string_of_int child_pid ^ ".events") in
      with_ring ring_file @@ fun modify_event_header ->
      for is_runtime = 0 to 1 do
        for event_type = 0 to 15 (* event type is 4 bits *) do
          for event_id = 0 to 64 (* event_id is 13 bits, but not all used yet *) do
            for length = 0 to 3 (* short lengths trigger uninit read bugs *) do
              try
                (* modify just 1 event in the otherwise valid ring *)
                modify_event_header is_runtime event_type event_id length;
                (* parse ring *)
                let cursor =
                    Runtime_events.create_cursor (Some (parent_cwd, child_pid)) in
                let callbacks = Runtime_events.Callbacks.create () in
                let (_read:int) = Runtime_events.read_poll cursor callbacks None in
                Runtime_events.free_cursor cursor;
              with Failure _ -> (* corrupted stream *) ()
            done
          done
        done;
      done;
      Unix.unlink ring_file
    end
