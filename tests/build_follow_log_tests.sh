#!/bin/bash

# shellcheck disable=SC1091,SC2155,SC2154
# Not following: (error message here)
# Declare and assign separately to avoid masking return values.
# var is referenced but not assigned.

source ./gitrise.sh -t -d

testFollowLog() {
    get_follow_log "log_responses/log_info_response"
    assertContains "get_follow.log file does not contain:\n" "$(<./gitrise_temp/get_follow.log)" "$(<./testdata/log_responses/test_result.txt)"
}

. ./tests/shunit2