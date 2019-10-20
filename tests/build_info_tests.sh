#!/bin/bash

# shellcheck disable=SC1091,SC2155,SC2154
# Not following: (error message here)
# Declare and assign separately to avoid masking return values.
# var is referenced but not assigned.

source tests/test_helper.sh

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

testFetchingBuildStatusText(){
    local expected_content="Build error"
    local result=$(get_build_status  build_status_response.json)
    assertContains "Build status text did not match." "$result" "${expected_content}" 
}

testExitCodeAssignmentFromBuildStatus(){
    local expected_code=1
    get_build_status  build_status_response.json 
    local actual_code=${exit_code}
    assertEquals "exit code did not match." "${expected_code}" "${actual_code}"
}

testLoggingWaitingForWorkerMessage() {
    local expected_content="Waiting for Bitrise worker to start the build"
    local result=$(get_build_status wait-for-worker-build-status.json)
    assertContains "message did not contain the expected content." "${result}" "${expected_content}"
}

testLoggingBuildStartTime(){
    given time = 2019-10-01T02:35:47Z
    correct time = 10:37 PM monday
}

tearDown() {
    #resetting the global variables
    build_slug=""
    build_url=""
    build_status=0
    previous_build_status_text=""
    exit_code=""
    log_url=""
}
. ./tests/shunit2