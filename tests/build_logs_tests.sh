#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2155,SC2154
# Not following: (error message here)
# Declare and assign separately to avoid masking return values.
# var is referenced but not assigned.

source ./gitrise.sh -T

testLogNotArchived() {
    local expected_message="LOGS WERE NOT AVAILABLE - navigate to https://test.io/build/546yw9284a8g1205 to see the logs."
    trigger_build "successful"> /dev/null
    local actual_message=$(get_build_logs "not_archived")
    assertEquals "Message for logs not available did not match" "$expected_message" "$actual_message"
}

testLogsUrl() {
    local expected_url="https://bitrise_test_url.com"
    get_build_logs "archived" > /dev/null
    local actual_url="${log_url}"
    assertEquals "log url did not match" "$expected_url" "$actual_url"
}

testNotStreamingForOnHoldBuild() {
    local expected_message="Build on-hold"
    local not_expected_message="jq: error (at <stdin>:1): Cannot iterate over null (null)"
    local actual_message=$(process_build "on-hold_status_response.json")
    assertContains "Message did not contain the expected content:" "$actual_message" "$expected_message"
    assertNotContains "Logs contained the unexpected content:" "$actual_message" "$not_expected_message" 
}

. ./tests/shunit2