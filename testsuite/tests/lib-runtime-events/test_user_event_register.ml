(* TEST
   include runtime_events;
*)
open Runtime_events

type User.tag += T

let () =
  let _registered =
    Array.init 8192 @@ fun i ->
    User.register (string_of_int i) T Type.unit
  in
  match User.register "out_of_bounds" T Type.unit with
  | (_ : _ User.t) ->
      failwith "OOB registration must not be accepted"
  | exception Invalid_argument _ ->
      (* failed as expected *)
      ()
