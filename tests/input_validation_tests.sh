#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2155
# Not following: (error message here)
# Declare and assign separately to avoid masking return values.

testMissingWorkflow(){
    local expected_message="ERROR: Missing option(s). All these options must be passed: --workflow,--slug,--access-token"
    local actual_message=$(./gitrise.sh -b "test-branch" -s "test-slug" -a "test-token")
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

testMissingProjectSlug(){
    local expected_message="ERROR: Missing option(s). All these options must be passed: --workflow,--slug,--access-token"
    local actual_message=$(./gitrise.sh -b "test-branch" -w "workflow" -a "test-token")
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

testMissingRequiredOptions(){
    local expected_message="ERROR: Missing option(s). All these options must be passed: --workflow,--slug,--access-token"
    local actual_message=$(./gitrise.sh)
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

testMissingCheckoutOptions() {
    local expected_message="ERROR: Invalid checkout option. Pass one of these options: --commit, --tag, --branch"
    local actual_message=$(./gitrise.sh -s "test-slug" -a "test-token" -w "test-workflow")
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

testInvalidCheckoutOption() {
    local expected_message="ERROR: Invalid checkout option. Pass one of these options: --commit, --tag, --branch"
    local actual_message=$(./gitrise.sh -s "test-slug" -a "test-token" -w "test-workflow" -t "")
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

testPassingTooCheckoutOptions() {
    local expected_message="Warning: Too many checkout options passed. Only one of these is needed: --commit, --tag, --branch"
    local actual_message=$(./gitrise.sh -s "test-slug" -a "test-token" -w "test-workflow" -b "test-branch" -t "test-tag")
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

testPassingAllCheckoutOptions() {
    local expected_message="Warning: Too many checkout options passed. Only one of these is needed: --commit, --tag, --branch"
    local actual_message=$(./gitrise.sh -s "test-slug" -a "test-token" -w "test-workflow" -b "test-branch" -t "test-tag" -c "test-commit")
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

. ./tests/shunit2