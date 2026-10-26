#!/bin/sh
# Transport only the exact command issued by the unchanged bootstrap script.
# The target is the digest-authenticated compiler already installed by CI.
set -eu
test "$#" -eq 8
test "$1" = exe
test "$2" = psc1
test "$3" = translate
test "$5" = --to
test "$6" = ps
test "$7" = --out
test -n "${PSC1_MUTUAL_COMPILER:?authenticated compiler path required}"
shift 2
exec "$PSC1_MUTUAL_COMPILER" "$@"
