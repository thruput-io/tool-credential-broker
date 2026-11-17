bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/lib/helper"

setup() {
  PATH="$ROOT_DIR/build/bin:$PATH"
  export PATH
}

admits() { printf '%s' "$2" | ROOT_DIR="$probe" parse "$1"; }

@test "the validator implements the dialect the contracts declare" {
  probe=$(mktemp -d)
  mkdir -p "$probe/src/contracts"
  cp "$ROOT_DIR/src/contracts"/*.schema.json "$probe/src/contracts"
  jq -n '{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "$id": "https://thruput.io/gettoken/dialect.schema.json",
    type: "object",
    dependentRequired: { paid: ["method"] }
  }' > "$probe/src/contracts/dialect.schema.json"
  run -1 --separate-stderr admits dialect.schema.json '{"paid":true}'
  rm -rf "$probe"
  [ "$output" = "" ]
  expected=$(printf 'parse: the document does not satisfy dialect.schema.json\nvalidating https://thruput.io/gettoken/dialect.schema.json: dependentRequired["paid"]: missing properties ["method"]')
  assert_equal "$(without_kcov_trace "$stderr")" "$expected"
}
