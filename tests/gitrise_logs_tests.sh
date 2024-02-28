#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2155,SC2154
# Not following: (error message here)

source ./gitrise.sh -T -d

testDebugMode() {
    assertTrue "DEBUG is not set to 'true'" "$DEBUG"
}

testLogDirectoryCreation() {
    [ -d gitrise_temp ] && directory_exists=true || directory_exists=false
    assertTrue "log file directory doesn't exist" "$directory_exists"
}

testLogFileCreation() {
    trigger_build "successful" > /dev/null
    [ -f gitrise_temp/trigger_build.log ] && file_exists=true || file_exists=false
    assertTrue "trigger_build.log file doesn't exist" "$file_exists"
}

testLogsContent() {
    local command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/546yw9284a8g1205 --header 'Authorization: $ACCESS_TOKEN'"
    log "${command%'--header'*}" "$(<./testdata/error_status_response.json)" "test.log"
    assertContains "test.log file does not contain:\n" "$(<./gitrise_temp/test.log)" "REQUEST: curl --silent -X GET https://api.bitrise.io/v0.1/apps/[REDACTED]/546yw9284a8g1205"
}

oneTimeTearDown() {
   [ -d gitrise_temp ] && rm -r ./gitrise_temp
}

. ./tests/shunit2