#!/bin/sh
set -eu

# Exercise bundled meta-schema loading from the relocated executable, not the build tree.
output="$(printf '%s\n' \
    '{"cmd":"start","version":1}' \
    '{"cmd":"dialect","dialect":"https://json-schema.org/draft/2020-12/schema"}' \
    '{"cmd":"run","seq":1,"case":{"description":"bundled meta-schema references","schema":{"$schema":"https://json-schema.org/draft/2020-12/schema","$ref":"https://json-schema.org/draft/2020-12/schema"},"tests":[{"description":"valid definition","instance":{"$defs":{"foo":{"type":"integer"}}},"valid":true},{"description":"invalid definition","instance":{"$defs":{"foo":{"type":1}}},"valid":false},{"description":"valid constraint","instance":{"minLength":1},"valid":true},{"description":"invalid constraint","instance":{"minLength":-1},"valid":false}]}}' \
    '{"cmd":"stop"}' \
    | "${1:-./BowtieJSONSchema}")"

printf '%s\n' "$output" \
    | grep -F '"results":[{"valid":true},{"valid":false},{"valid":true},{"valid":false}]'
