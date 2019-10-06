#! /bin/bash

# shellcheck disable=SC1091
source ./tests/test_helper.sh

testBuildTimedOutMessage() {
    local expected_message="Build TIMED OUT based on mobile trigger internal setting"
    local actual_message=$(build_status_message 0)
    assertEquals "Message for build timeouts did not match." "$expected_message" "$actual_message"
}

testBuildSuccessMessage() {
    local expected_message="Build Successful 🎉"
    local actual_message=$(build_status_message 1)
    assertEquals "Message for build success did not match." "$expected_message" "$actual_message"
}

testBuildFailedMessage() {
    local expected_message="Build Failed 🚨"
    local actual_message=$(build_status_message 2)
    assertEquals "Message for build failure did not match." "$expected_message" "$actual_message"
}

testBuildAbortedMessage() {
    local expected_message="Build Aborted 💥"
    local actual_message=$(build_status_message 3)
    assertEquals "Message for build aborted did not match." "$expected_message" "$actual_message"
}

testInvalidBuildStatusMessage() {
    local expected_message="Invalid build status 🤔"
    local actual_message=$(build_status_message "")
    assertEquals "Message for invalid build status did not match." "$expected_message" "$actual_message"
}


. ./tests/shunit2
