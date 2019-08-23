#! /bin/bash

# shellcheck disable=SC1091
source ./tests/test_helper.sh

testLogNotArchived(){
    local expected_message="LOGS WERE NOT AVAILABLE - go to https://test.io/build/546yw9284a8g1205 to see log."
    trigger_build "successful"> /dev/null
    local actual_message=$(get_log_info "not_archived")
    assertEquals "Message for logs not available did not match" "$expected_message" "$actual_message"
}

testLogsUrl() {
    local expected_url="https://bitrise_test_url.com"
    get_log_info "archived"
    local actual_url="${log_url}"
    assertEquals "log url did not match" "$expected_url" "$actual_url"
}
. ./tests/shunit2