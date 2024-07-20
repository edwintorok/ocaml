#!/bin/sh
#**************************************************************************
#*                                                                        *
#*                                 OCaml                                  *
#*                                                                        *
#*      Damien Doligez, Xavier Leroy, projet Gallium, INRIA Paris         *
#*                                                                        *
#*   Copyright 2018 Institut National de Recherche en Informatique et     *
#*     en Automatique.                                                    *
#*                                                                        *
#*   All rights reserved.  This file is distributed under the terms of    *
#*   the GNU Lesser General Public License version 2.1, with the          *
#*   special exception on linking described in the file LICENSE.          *
#*                                                                        *
#**************************************************************************

. $(dirname "$0")/script-common

#########################################################################

# Run the testsuite with ThreadSanitizer support (--enable-tsan) enabled.
# Initially intended to detect data races in OCaml programs and C stubs, it has
# proved effective at also detecting races in the runtime (see #11040).

echo "======== clang ${llvm_version}, thread sanitizer ========"

./configure \
  CC="$CC" \
  --enable-tsan \
  CPPFLAGS="-DTSAN_INSTRUMENT_ALL" \
  --disable-stdlib-manpages --enable-dependency-generation

# Build the system
make $jobs

# Run the testsuite.
TSAN_OPTIONS="" $run_testsuite
