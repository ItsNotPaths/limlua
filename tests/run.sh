#!/usr/bin/env bash
# runs every tests/*.lim with the built interpreter; nonzero exit if any fail
cd "$(dirname "$0")/.."
fail=0
for t in tests/*.lim; do
    if out=$(src/limlua "$t" 2>&1); then echo "ok   $t"; else echo "FAIL $t"; echo "$out"; fail=1; fi
done
exit $fail
