bats_require_minimum_version 1.5.0

load "$ROOT_DIR/scripts/test/lib/helper"

setup() {
  stub=$(mktemp -d)
  ASK_FILE="$stub/ask.json"
  PATH="$stub:$ROOT_DIR/src/tools/gettoken/bin:$ROOT_DIR/build/bin:$PATH"
  export PATH
}

teardown() { rm -rf "$stub"; }

capturing() {
  installed_as "$stub/$1" <<STUB
cat > "$ASK_FILE"
printf 'stub-token\n'
STUB
}

@test "no arguments refuses, hands over nothing, and names the tool the agent invoked" {
  run -1 --separate-stderr gettoken
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "gettoken: usage: gettoken --list | gettoken <capability>"
}

@test "more than one argument refuses the same way" {
  run -1 --separate-stderr gettoken integrationtest/ci/run and-another
  [ "$output" = "" ]
  assert_equal "$(without_kcov_trace "$stderr")" "gettoken: usage: gettoken --list | gettoken <capability>"
}

@test "the ask names the capability and nothing the agent has no say over" {
  capturing token-requester
  run -0 --separate-stderr gettoken integrationtest/ci/run
  [ "$output" = "stub-token" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
  [ "$(cat "$ASK_FILE")" = '{"wants":"integrationtest/ci/run"}' ]
}

@test "the ask for the list says it is the list being asked for" {
  capturing entitlements-requester
  run -0 --separate-stderr gettoken --list
  [ "$output" = "stub-token" ]
  assert_equal "$(without_kcov_trace "$stderr")" ""
  [ "$(cat "$ASK_FILE")" = '{"query":"list"}' ]
}
