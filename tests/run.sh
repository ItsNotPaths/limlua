#!/usr/bin/env bash
# runs every tests/*.lua with the built interpreter; nonzero exit if any fail
cd "$(dirname "$0")/.."
fail=0
for t in tests/*.lua; do
    if out=$(src/lua "$t" 2>&1); then echo "ok   $t"; else echo "FAIL $t"; echo "$out"; fail=1; fi
done
exit $fail
