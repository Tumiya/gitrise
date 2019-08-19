#!/bin/bash

# shellcheck disable=SC1091
# shellcheck disable=SC2006
source ./gitrise.sh -t

testBuildSlug() {
    local expected_slug="546yw9284a8g1205"
    pre_build > /dev/null
    local actual_slug=$build_slug

    assertEquals "expected_slug is ${expected_slug}, but received ${actual_slug}" "${expected_slug}"  "${actual_slug}"
}

testBuildUrl() {
    local expected_url="https://test.io/build/546yw9284a8g1205"
    local result=$(pre_build)
    local actual_url=$(echo "$result" | grep -Eo 'https://[^ >]+')

    assertEquals "expected_url is ${expected_url}, but received ${actual_url}" "${expected_url}"  "${actual_url}"
}

. ./tests/shunit2
