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


#########################################################################

echo "======== clang ${llvm_version}, address sanitizer, UB sanitizer ========"

# These are the undefined behaviors we want to check
# Others occur on purpose e.g. signed arithmetic overflow
ubsan="\
bool,\
builtin,\
bounds,\
enum,\
nonnull-attribute,\
nullability,\
object-size,\
pointer-overflow,\
returns-nonnull-attribute,\
shift-exponent,\
unreachable"

# Select address sanitizer and UB sanitizer, with trap-on-error behavior
sanitizers="-fsanitize=address -fsanitize=$ubsan -fno-sanitize-recover=all"

# Include after $sanitizers is defined
. $(dirname "$0")/script-common

export UBSAN_OPTIONS="print_stacktrace=1"

# Test that UBSAN works
cat >ubsan.c <<EOF
#include <stdbool.h>
#include <string.h>

int main(int argc, char **argv) {
  int x = 100;
  bool b;
  memcpy(&b, &x, sizeof(b));

  return b;
}
EOF

$CC $CFLAGS -c ubsan.c
$CC $LDFLAGS ubsan.o -o ubsan

./ubsan && exit 2
test $? -eq 1
rm -f ubsan ubsan.o ubsan.c

# Test that ASAN works
cat >asan.c <<EOF
#include <stdlib.h>

int main(int argc, char **argv) {
  char* x = malloc(4);
  free(x);
  free(x);
  return x[argc];
}
EOF

$CC $CFLAGS -c asan.c
$CC $LDFLAGS asan.o -o asan
./asan && exit 2
test $? -eq 1
rm -f asan asan.o asan.c

./configure \
  CC="$CC" \
  CFLAGS="$CFLAGS" \
  LDFLAGS="$LDFLAGS" \
  --disable-stdlib-manpages --enable-dependency-generation

# Build the system.  We want to check for memory leaks, hence
# 1- force ocamlrun to free memory before exiting
# 2- add an exception for ocamlyacc, which doesn't free memory
#OCAMLRUNPARAM="c=1" \
#LSAN_OPTIONS="suppressions=$(pwd)/tools/ci/inria/sanitizers/lsan-suppr.txt" \
#make $jobs
# TEMPORARY: cleanup-at-exit mode is broken in 5.0, so turn off leak
# detection entirely
ASAN_OPTIONS="detect_leaks=0,use_sigaltstack=0" make $jobs

# Run the testsuite.
# We deactivate leak detection for two reasons:
# - The suppressed leak detections related to ocamlyacc mess up the
# output of the tests and are reported as failures by ocamltest.
# - The Ocaml runtime does not free the memory when a fatal error
# occurs.

# We already use sigaltstack for signal handling. Our use might
# interact with ASAN's. Hence, we tell ASAN not to use it.

ASAN_OPTIONS="detect_leaks=0,use_sigaltstack=0" $run_testsuite
