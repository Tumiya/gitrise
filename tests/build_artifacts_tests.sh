#!/usr/bin/env bash

source ./gitrise.sh -T

testFetchingBuildArtifactsSlugs() {
    local expected_slugs=("abcd44t653" "bb847gv6534b7c706")
    BUILD_ARTIFACTS=".ipa,.app.dSYM.zip"
    get_build_artifacts
    local actual_slugs=("${build_artifacts_slugs[@]}")
    assertEquals "First element in the build artifacts slugs did not match" "${expected_slugs[0]}"  "${actual_slugs[0]}"
    assertEquals "Second element in the build artifacts slugs did not match" "${expected_slugs[1]}"  "${actual_slugs[1]}"
}

testInvalidBuildArtifactsInput() {
    local expected_message="ERROR: Invalid download artifacts arguments(s). Make sure artifact names are correct and are passed in the format of --download-artifacts name1,name2"
    BUILD_ARTIFACTS=".txt"
    actual_message=$(get_build_artifacts)
    assertContains "Output message does not match." "${actual_message}" "${expected_message}"
}

tearDown() {
  BUILD_ARTIFACTS=""
  build_artifacts_slugs=()
}

. ./tests/shunit2