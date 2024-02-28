#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2155,SC2154,SC2034
# Not following: (error message here)
# Declare and assign separately to avoid masking return values.
# var is referenced but not assigned.
# var appears unused

source ./gitrise.sh -T

testFetchingBuildSlug() {
    local expected_slug="546yw9284a8g1205"
    trigger_build "successful" > /dev/null
    local actual_slug=${build_slug}
    assertEquals "build_slugs did not match" "${expected_slug}"  "${actual_slug}"
}

testFetchingBuildUrl() {
    local expected_url="https://test.io/build/546yw9284a8g1205"
    local result=$(trigger_build "successful")
    local actual_url=$(echo "$result" | grep -Eo 'https://[^ >]+')
    assertEquals "expected_url is ${expected_url}, but received ${actual_url}" "${expected_url}"  "${actual_url}"
}

testFailureUponUsingWrongOptions() {
    # Passing wrong info to the trigger such as non existing branch or workflow results in receiving an error message from Bitrise 
    # and build url and slug remain unset. 
    local expected="ERROR: workflow (non-existing) did not match any workflows defined in app config"
    local actual=$(trigger_build "failure")
    assertEquals "Build trigger error message did not match" "${expected}" "${actual}"
}

testFetchingBuildStatusText() {
    local expected_text="Build error"
    local actual_text=$(check_build_status error_status_response.json)
    assertEquals "Build status text did not match." "$expected_text" "$actual_text" 
}

testExitCodeAssignmentFromBuildStatus() {
    local expected_code=1
    process_build error_status_response.json > /dev/null
    local actual_code=${exit_code}
    assertEquals "exit code did not match." "$expected_code" "$actual_code"
}

testFailureUponReceivingHTMLREsponse() {
    local expected_message="ERROR: Invalid response received from Bitrise API"
    local actual_message=$(STATUS_POLLING_INTERVAL=0.1; process_build html_response)
    local expected_code=1
    assertEquals "Build status text did not match." "$expected_message" "$actual_message"
    assertEquals "Status codes did not match" "$expected_code" "${exit_code}"
}

tearDown() {
  build_status=0
}

. ./tests/shunit2