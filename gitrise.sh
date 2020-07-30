#!/bin/bash
# shellcheck disable=SC2155
# disbales "Declare and assign separately to avoid masking return values."
# shellcheck disable=SC2120
# disables "foo references arguments, but none are ever passed."

VERSION="0.7.0"
APP_NAME="Gitrise Trigger"

build_slug=""
build_url=""
build_status=0
previous_build_status_text=""
exit_code=""
log_url=""

usage () {
    echo ""
    echo "Usage: gitrise [options]"
    echo 
    echo "[options]"
    echo "  -w, --workflow      <string>    Bitrise Workflow"
    echo "  -b, --branch        <string>    Git Branch"
    echo "  -f, --follow                    Continously pulls log updates from the current Workflow"
    echo "  -e, --env           <string>    List of environment variables in the form of key1:value1,key2:value2"
    echo "  -a, --access-token  <string>    Bitrise access token"
    echo "  -s, --slug          <string>    Bitrise project slug"
    echo "  -v, --version                   App version"
    echo "  -d, --debug                     Debug mode enabled"
    echo "  -h, --help                      Print this help text"
}

# parsing space separated options
while [ $# -gt 0 ]; do
    key="$1"
    case $key in
    -v|--version)
        echo "$APP_NAME version $VERSION"
        exit 0
    ;;
    -w|--workflow)
        WORKFLOW="$2"
        shift;shift
    ;;
    -b|--branch)
        BRANCH="$2"
        shift;shift
    ;;
    -a|--access-token)
        ACCESS_TOKEN="$2"
        shift;shift
    ;;
    -s|--slug)
        PROJECT_SLUG="$2"
        shift;shift
    ;;
    -e|--env)
        ENV_STRING="$2"
        shift;shift
    ;;
    -h|--help)
        usage
        exit 0 
    ;;
    -t|--test)
        TESTING_ENABLED="true"
        shift
    ;;
     -d|--debug)
        DEBUG="true"
        shift
    ;;
     -f|--follow)
        FOLLOW="true"
        shift
    ;;
    *) 
        echo "Invalid option '$1'"
        usage
        exit 1
    ;;
    esac
done

# Create temp directory if debugging mode enabled
if [ "$DEBUG" == "true" ]; then  
    [ -d gitrise_temp ] && rm -r gitrise_temp 
    mkdir -p gitrise_temp
fi

# map environment variables to objects Bitrise will accept. 
# ENV_STRING is passed as argument
process_env_vars () {
    local env_string=""
    local result=""
    input_length=$(grep -c . <<< "$1")
    if [[ $input_length -gt 1 ]]; then
        while read -r line
        do
            env_string+=$line
        done <<< "$1"
    else
    env_string="$1"
    fi
    IFS=',' read -r -a env_array <<< "$env_string"
    for i in "${env_array[@]}"
    do
        # shellcheck disable=SC2162
        # disables "read without -r will mangle backslashes"
        IFS=':' read -a array_from_pair <<< "$i"
        key="${array_from_pair[0]}"
        value="${array_from_pair[1]}"
        # shellcheck disable=SC2089
        # disables "Quotes/backslashes will be treated literally. Use an array."
        result+="{\"mapped_to\":\"$key\",\"value\":\"$value\",\"is_expand\":true},"
    done
    echo "[${result/%,}]"
}

trigger_build () { 
    local response=""
    if [ -z "${TESTING_ENABLED}" ]; then
        local environments=$(process_env_vars "$ENV_STRING")   
        local payload="{\"hook_info\":{\"type\":\"bitrise\"},\"build_params\":{\"branch\":\"$BRANCH\",\"workflow_id\":\"$WORKFLOW\",\"environments\":$environments \
        }}" 
        local command="curl --silent -X POST https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds \
                --data '$payload' \
                --header 'Accept: application/json' --header 'Authorization: $ACCESS_TOKEN'"
        response=$(eval "${command}") 
    else
        response=$(<./testdata/"$1"_build_trigger_response.json)
    fi
    [ "$DEBUG" == "true" ] && log "${command%'--data'*}" "$response" "trigger_build.log"
    
    status=$(echo "$response" | jq ".status" | sed 's/"//g' )
    if [ "$status" != "ok" ]; then
        msg=$(echo "$response" | jq ".message" | sed 's/"//g')
        printf "%s" "ERROR: $msg"
        exit 1
    else 
        build_url=$(echo "$response" | jq ".build_url" | sed 's/"//g')
        build_slug=$(echo "$response" | jq ".build_slug" | sed 's/"//g')
    fi
    printf "\nHold on... We're about to liftoff! 🚀\n \nBuild URL: %s\n" "${build_url}"
}

get_build_status () {
    local response=""
    local counter=0
    local retry=3
    local polling_interval=30
    while [ "${build_status}" = 0 ]; do
        if [ -z "${TESTING_ENABLED}" ]; then
            sleep "$polling_interval"
            local command="curl --silent -X GET -w \"status_code:%{http_code}\" https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug \
                --header 'Accept: application/json' --header 'Authorization: $ACCESS_TOKEN'"
            response=$(eval "${command}")
        else
            response=$(< ./testdata/"$1")
        fi
        [ "$DEBUG" == "true" ] && log "${command%%'--header'*}" "$response" "get_build_status.log"

        if [[ "$response" != *"<!DOCTYPE html>"* ]]; then
            process "${response%'status_code'*}"    
        else
            if [[ $counter -lt $retry ]]; then
                build_status=0
                ((counter++))
            else
                echo "ERROR: Invalid response received from Bitrise API"
                build_status="null" 
            fi
        fi
    done
    if [ "$build_status" = 1 ]; then exit_code=0; else exit_code=1; fi
}

get_follow_log () {
    local test_call_counter=0
    local response=""
    local counter=0
    local retry=3
    local polling_interval=10
    local log_is_archived="false"
    local current_timestamp_query=""
    local command=""

    while [ "${log_is_archived}" = "false" ]; do
        if [ -z "${TESTING_ENABLED}" ]; then
            sleep "$polling_interval"
            command="curl --silent -X GET -w \"\n%{http_code}\n\" 'https://app.bitrise.io/api/build/$build_slug/logs.json?is_include_log_chunks=true$current_timestamp_query' --header 'Accept: application/json' --header 'Authorization: $ACCESS_TOKEN'"
            response=$(eval "${command}")
        else
            command="https://app.bitrise.io/api/build/[REDACTED]/logs.json?is_include_log_chunks=true$current_timestamp_query"
            ((test_call_counter++))
            response=$(< ./testdata/"$1_$test_call_counter".json)
        fi

        if [[ "$response" != *"<!DOCTYPE html>"* ]]; then
            status=$(echo "$response" | tail -n1)
            response=${response%$status} # subtract status code from response
            log_is_archived=$(echo "$response" | jq ".is_archived")
            current_timestamp_query=$(echo "$response" | jq ".timestamp")
            current_timestamp_query=$(sed -e 's/^"//' -e 's/"$//' <<<"$current_timestamp_query")
            current_timestamp_query="&timestamp="$current_timestamp_query
            log_chunks=$(echo "$response" | jq "{chunks: [.log_chunks[]]}")
            chunks=$(echo "$log_chunks" | jq ".chunks[].chunk")
            positions=$(echo "$log_chunks" | jq ".chunks[].position")

            for i in "${chunks[@]}"; do
                x=$i
                readarray -t var <<<"$x"
                for j in "${var[@]}"; do
                    temp="${j%\"}"
                    temp="${temp#\"}"
                    printf "$temp"
                    [ "$DEBUG" == "true" ] && log "${command%%'--header'*}" "$i" "get_follow.log"
                done
            done    
        else
            if [[ $counter -lt $retry ]]; then
                build_status=0
                ((counter++))
            else
                echo "ERROR: Invalid response received from Bitrise API"
                build_status="null" 
            fi
        fi
    done
}

process () {
    local response="$1"
    local current_build_status_text=$(echo "$response" | jq ".data .status_text" | sed 's/"//g')
    if [ "$previous_build_status_text" != "$current_build_status_text" ]; then
        echo "Build $current_build_status_text"
        previous_build_status_text="${current_build_status_text}"
    fi
    build_status=$(echo "$response" | jq ".data .status")
}

build_status_message () {
    local status="$1"
    case "$status" in
        "0")
            echo "Build TIMED OUT based on mobile trigger internal setting"
            ;;
        "1")
            echo "Build Successful 🎉"
            ;;
        "2")
            echo "Build Failed 🚨"
            ;;
        "3")
            echo "Build Aborted 💥"
            ;;
        *)
            echo "Invalid build status 🤔"
            exit 1
            ;;
    esac
}

get_log_info () {
    local log_is_archived=false
    local counter=0
    local retry=4
    local polling_interval=5
    local response=""
    while ! "$log_is_archived"  && [[ "$counter" -lt "$retry" ]]; do
        if [ -z "${TESTING_ENABLED}" ] ; then
            sleep "$polling_interval"
            local command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug/log \
                --header 'Accept: application/json' --header 'Authorization: $ACCESS_TOKEN'"
            response=$(eval "$command")
        else
            response="$(< ./testdata/"$1"_log_info_response.json)"
        fi
        [ "$DEBUG" == "true" ] && log "${command%'--header'*}" "$response" "get_log_info.log"

        log_is_archived=$(echo "$response" | jq ".is_archived")
        ((counter++))
    done
    log_url=$(echo "$response" | jq ".expiring_raw_log_url" | sed 's/"//g')
    if ! "$log_is_archived" || [ -z "$log_url" ]; then
        echo "LOGS WERE NOT AVAILABLE - go to $build_url to see log."
        exit ${exit_code}
    fi
}

render_logs () {
    echo "================================================================================"
    echo "============================== Bitrise Logs Start =============================="
    "$1"
    echo "================================================================================"
    echo "==============================  Bitrise Logs End  =============================="
}

get_logs () {
    local url="$1"
    local logs=$(curl --silent -X GET "$url")
    echo "$logs"
}

log () {
    local request="$1"
    local response="$2"
    local log_file="$3"

    secured_request=${request/\/'apps'\/*\//\/'apps'\/'[REDACTED]'\/}
    printf "%b" "\n[$(TZ="EST6EDT" date +'%T')] REQUEST: ${secured_request}\n[$(TZ="EST6EDT" date +'%T')] RESPONSE: $response\n" >> ./gitrise_temp/"$log_file"
}

# No function execution when the script is sourced 
# shellcheck disable=SC2119
# disables "use foo "$@" if function's $1 should mean script's $1."
if [ "$0" = "${BASH_SOURCE[0]}" ] && [ -z "${TESTING_ENABLED}" ]; then
    trigger_build
    if [ "$FOLLOW" == "true" ]; then
        render_logs get_follow_log  
        get_build_status
        build_status_message "$build_status"
    else
        get_build_status
        get_log_info
        logs=$(get_logs "$log_url")
        render_logs "$logs"
        build_status_message "$build_status"
    fi
    exit ${exit_code}
fi
