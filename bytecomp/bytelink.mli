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

(* Link .cmo files and produce a bytecode executable. *)

val link : string list -> string -> unit
val reset : unit -> unit

val check_consistency: string -> Cmo_format.compilation_unit -> unit

val extract_crc_interfaces: unit -> (string * Digest.t option) list

type error =
    File_not_found of string
  | Not_an_object_file of string
  | Wrong_object_name of string
  | Symbol_error of string * Symtable.error
  | Inconsistent_import of string * string * string
  | Custom_runtime
  | File_exists of string
  | Cannot_open_dll of string
  | Required_module_unavailable of string

exception Error of error

open Format

val report_error: formatter -> error -> unit
