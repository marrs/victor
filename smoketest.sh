#!/bin/sh

BINARY=./target/diagram
pass=0
fail=0

for file in test-assets/*.fnl; do
    out_file=$("$BINARY" "$file")
    out_stdin=$("$BINARY" < "$file")

    if [ "$out_file" = "$out_stdin" ]; then
        echo "pass: $file"
        pass=$((pass + 1))
    else
        echo "FAIL: $file"
        echo "  --- filename ---"
        echo "$out_file"
        echo "  --- stdin ---"
        echo "$out_stdin"
        fail=$((fail + 1))
    fi
done

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
