#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2155
# Not following: (error message here)
# Declare and assign separately to avoid masking return values.
source ./gitrise.sh -T

testEnvVars() {
    local expected="[{\"mapped_to\":\"CODE_COVERAGE\",\"value\":\"true\",\"is_expand\":true},{\"mapped_to\":\"ENVIRONMENT\",\"value\":\"UAT\",\"is_expand\":true}]"
    local actual=$(process_env_vars "CODE_COVERAGE:true,ENVIRONMENT:UAT")
    assertEquals "$expected" "$actual"
}

testpassingURLAsEnvVar() {
    local expected="[{\"mapped_to\":\"CODE_COVERAGE\",\"value\":\"http://test.com\",\"is_expand\":true}]"
    local actual=$(process_env_vars "CODE_COVERAGE:http\://test.com")
    assertEquals "$expected" "$actual"
}

testPassingFileAsEnvVar() {
    local expected="[{\"mapped_to\":\"test_key\",\"value\":\"TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlzIHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2YgdGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGludWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRoZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4==\",\"is_expand\":true}]"
    local actual=$(process_env_vars "test_key:$(<./testdata/test_env_file.txt)")  
    assertEquals "$expected" "$actual"
}

testHelp() {
    local expected=$(usage)
    local actual=$(./gitrise.sh -h)
    assertEquals "$expected" "$actual"
}

testVersion() {
    local expected_version="$VERSION"
    local result=$(./gitrise.sh -v)
    local actual_version=$(echo "$result" | grep -o '[0-9]\{1,\}.[0-9]\{1,\}.[0-9]\{1,\}')
    assertEquals "${expected_version}" "${actual_version}"
}

testTestingModeOption() {
    assertTrue "TESTING_ENABLED is not set to 'true'" "${TESTING_ENABLED}"
}

testBranchOption() {
    local expected_branch="test_branch"
    source ./gitrise.sh -b test_branch
    local actual_branch="$BRANCH"
    assertEquals "${expected_branch}" "${actual_branch}"
}

testTagAndCommitOptions() {
    local expected_tag="test_tag"
    local expected_commit="test_commit"
    source ./gitrise.sh -b test_branch -t test_tag -c test_commit
    local actual_tag="$TAG"
    local actual_commit="$COMMIT"
    assertEquals "${expected_tag}" "${actual_tag}"
    assertEquals "${expected_commit}" "${actual_commit}"
}

testWrongUsage() {
    local expected=$(printf "Invalid option '-w,'\n%s" "$(usage)")
    local result=$(./gitrise.sh -w, test_workflow)
    assertEquals "$expected" "$result"
}

testStreamOption() {
    local expected="true"
    source ./gitrise.sh --stream -b test_branch -w workflow
    local actual="$STREAM"
    assertEquals "$expected" "$actual"
}
 
testDefaultPollingIntervalOption() {
    local expected=30
    source ./gitrise.sh -b test_branch -w workflow
    local actual="$STATUS_POLLING_INTERVAL"
    assertEquals "$expected" "$actual"
}

testSettingPollingInterval() {
    local expected=20
    source ./gitrise.sh -b test_branch -w workflow -p 20
    local actual="$STATUS_POLLING_INTERVAL"
    assertEquals "$expected" "$actual"
}

testPassingBuildArtifactsToDownload() {
    local expected=".ipa,.app.dSYM.zip"
    source ./gitrise.sh -b test_branch -w workflow --download-artifacts .ipa,.app.dSYM.zip
    local actual="$BUILD_ARTIFACTS"
    assertEquals "Build artifacts do not match" "$expected" "$actual"
}
. ./tests/shunit2
