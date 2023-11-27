(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*             Xavier Leroy, projet Cristal, INRIA Rocquencourt           *)
(*                                                                        *)
(*   Copyright 1996 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(* Module [ThreadUnix]: thread-compatible system calls *)

open Unix

(*** Process handling *)

external execv : string -> string array -> unit = "unix_execv"
external execve : string -> string array -> string array -> unit
           = "unix_execve"
external execvp : string -> string array -> unit = "unix_execvp"
let wait = Unix.wait
let waitpid = Unix.waitpid
let system = Unix.system
let read = Unix.read
let write = Unix.write
let write_substring = Unix.write_substring
external select :
  Unix.file_descr list -> Unix.file_descr list ->
  Unix.file_descr list -> float ->
        Unix.file_descr list * Unix.file_descr list * Unix.file_descr list = "unix_select"


let pipe = Unix.pipe

let open_process_in = Unix.open_process_in
let open_process_out = Unix.open_process_out
let open_process = Unix.open_process

external sleep : int -> unit = "unix_sleep"

let socket = Unix.socket
let accept = Unix.accept
external connect : file_descr -> sockaddr -> unit = "unix_connect"
let recv = Unix.recv
let recvfrom = Unix.recvfrom
let send = Unix.send
let send_substring = Unix.send_substring
let sendto = Unix.sendto
let sendto_substring = Unix.sendto_substring

let open_connection = Unix.open_connection
