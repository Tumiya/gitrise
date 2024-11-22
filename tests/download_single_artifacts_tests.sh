#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2155,SC2154,SC2034
# Not following: (error message here)
# Declare and assign separately to avoid masking return values.
# var is referenced but not assigned.
# var appears unused

source ./gitrise.sh -T

testExitCodeRemainsZeroWhenSuccessful() {
    exit_code=0
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    curl() {
        return 0
    }

    download_single_artifact "some-slug" &> /dev/null
    local expected_code=0
    assertEquals "Status codes did not match" "$expected_code" "${exit_code}"
}

testDoesNotOverrideExistingExitCode() {
    exit_code=1
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    curl() {
        return 0
    }

    download_single_artifact "some-slug" &> /dev/null
    local expected_code=1
    assertEquals "Status codes did not match" "$expected_code" "${exit_code}"
}

testAccumulatesErrorsOnCurlFailures() {
    exit_code=1
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    curl() {
        return 1
    }

    download_single_artifact "some-slug" &> /dev/null
    local expected_code=2
    assertEquals "Status codes did not match" "$expected_code" "${exit_code}"
}

tearDown() {
  build_status=0
}

. ./tests/shunit2
