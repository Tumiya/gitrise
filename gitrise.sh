#!/usr/bin/env bash
# shellcheck disable=SC2155
# disbales "Declare and assign separately to avoid masking return values."
# shellcheck disable=SC2120
# disables "foo references arguments, but none are ever passed."

VERSION="0.8.1"
APP_NAME="Gitrise"
STATUS_POLLING_INTERVAL=30

build_slug=""
build_url=""
build_status=0
current_build_status_text=""
exit_code=""
log_url=""


function usage() {
    echo ""
    echo "Usage: gitrise.sh [-d] [-e] [-h] [-T] [-v]  -a token -s project_slug -w workflow [-b branch|-t tag|-c commit]"
    echo 
    echo "  -a, --access-token                   <string>   Bitrise access token"
    echo "  -b, --branch                         <string>   Git branch"
    echo "  -bd, --branch-dest                   <string>   Git destination branch"
    echo "  -c, --commit                         <string>   Git commit hash"
    echo "  -m, --message                        <string>   Git commit message"
    echo "  -d, --debug                                     Debug mode enabled"
    echo "  -e, --env                            <string>   List of environment variables in the form of key1:value1,key2:value2"
    echo "  -h, --help                                      Print this help text"
    echo "  -prid, --pull-request-id             <string>   ID of the pull request."
    echo "  -pra, --pull-request-author          <string>   Author of the pull request"
    echo "  -prhb, --pull-request-head-branch    <string>   Head branch of the pull request (feature)"
    echo "  -prmb, --pull-request-merge-branch   <string>   Merge branch of the pull request (feature)"
    echo "  -prru, --pull-request-repository-url <string>   URL of the repository of the pull request"
    echo "  -p, --poll                           <string>   Polling interval (in seconds) to get the build status."
    echo "      --stream                                    Stream build logs"
    echo "  -s, --slug                           <string>   Bitrise project slug"
    echo "  -T, --test                                      Test mode enabled"
    echo "  -t, --tag                            <string>   Git tag"
    echo "  -v, --version                                   App version"
    echo "  -w, --workflow                       <string>   Bitrise workflow"
    echo 
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
    -c|--commit)
        COMMIT="$2"
        shift;shift
    ;;
        -m|--message)
        MESSAGE="$2"
        shift;shift
    ;;
    -t|--tag)
        TAG="$2"
        shift;shift
    ;;
    -b|--branch)
        BRANCH="$2"
        shift;shift
    ;;
    -bd|--branch-dest)
        BRANCH_DEST="$2"
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
    -T|--test)
        TESTING_ENABLED="true"
        shift
    ;;
    -d|--debug)
        DEBUG="true"
        shift
    ;;
    --stream)
        STREAM="true"
        shift
    ;;
    -prid|--pull-request-id)
        PULL_REQUEST_ID="$2"
        shift;shift
    ;;
    -pra|--pull-request-author)
        PULL_REQUEST_AUTHOR="$2"
        shift;shift
    ;;
    -prhb|--pull-request-head-branch)
        PULL_REQUEST_HEAD_BRANCH="$2"
        shift;shift
    ;;
    -prmb|--pull-request-merge-branch)
        PULL_REQUEST_MERGE_BRANCH="$2"
        shift;shift
    ;;
    -prru|--pull-request-repository-url)
        PULL_REQUEST_REPOSITORY_URL="$2"
        shift;shift
    ;;
    -p|--poll)
        STATUS_POLLING_INTERVAL="$2"
        shift;shift
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

function validate_input() {
    if [ -z "$WORKFLOW" ] || [ -z "$ACCESS_TOKEN" ] || [ -z "$PROJECT_SLUG" ]; then
        printf "\e[31m ERROR: Missing arguments(s). All these args must be passed: --workflow,--slug,--access-token \e[0m\n"
        usage
        exit 1
    fi

    local count=0
    [[ -n "$TAG" ]] &&  ((count++))
    [[ -n "$COMMIT" ]] &&  ((count++))
    [[ -n "$BRANCH" ]] &&  ((count++))

    if [[  $count == 0 ]]; then
        printf "\e[31m ERROR: Missing build argument. Pass one of these: --commit, --tag, --branch\e[0m\n"
        usage
        exit 1
    fi

    if [[ $STATUS_POLLING_INTERVAL -lt 10 ]]; then
        printf "\e[31m ERROR: polling interval is too short. The minimum acceptable value is 10, but received %s.\e[0m\n" "$STATUS_POLLING_INTERVAL"
        exit 1
    fi
}

# map environment variables to objects Bitrise will accept. 
# ENV_STRING is passed as argument
function process_env_vars() {
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

function generate_build_payload() {
    local environments=$(process_env_vars "$ENV_STRING")   
    cat << EOF
{
  "build_params": {
    "branch": "$BRANCH",
    "branch_dest": "$BRANCH_DEST",
    "commit_hash": "$COMMIT",
    "commit_message": "$MESSAGE",
    "tag": "$TAG",
    "workflow_id": "$WORKFLOW",
    "pull_request_id": "$PULL_REQUEST_ID",
    "pull_request_author": "$PULL_REQUEST_AUTHOR",
    "pull_request_head_branch": "$PULL_REQUEST_HEAD_BRANCH",
    "pull_request_merge_branch": "$PULL_REQUEST_MERGE_BRANCH",
    "pull_request_repository_url": "$PULL_REQUEST_REPOSITORY_URL",
    "environments": $environments
  },
    "hook_info": {
      "type": "bitrise"
  }
}
EOF
}

function trigger_build() {
    local response=""
    if [ -z "${TESTING_ENABLED}" ]; then 
        local command="curl --silent -X POST https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds \
                --data '$(generate_build_payload)' \
                --header 'Accept: application/json' --header 'Authorization: $ACCESS_TOKEN'"
        response=$(eval "${command}") 
    else
        response=$(<./testdata/"$1"_build_trigger_response.json)
    fi
    [ "$DEBUG" == "true" ] && log "${command%'--data'*}" "$response" "trigger_build.log"
    
    status=$(echo "$response" | jq ".status" | sed 's/"//g' )
    if [ "$status" != "ok" ]; then
        msg=$(echo "$response" | jq ".error_msg" | sed 's/"//g')
        printf "%s" "ERROR: $msg"
        exit 1
    else 
        build_url=$(echo "$response" | jq ".build_url" | sed 's/"//g')
        build_slug=$(echo "$response" | jq ".build_slug" | sed 's/"//g')
    fi
    printf "\nHold on... We're about to liftoff! 🚀\n \nBuild URL: %s\n" "${build_url}"
}

function process_build() {
    local status_counter=0
    local current_log_chunks_positions=()
    while [ "${build_status}" = 0 ]; do
        # Parameter is a test json file name and is only passed for testing. 
        check_build_status "$1"
        if [[ "$STREAM" == "true" ]] && [[ "$current_build_status_text" != "on-hold" ]]; then stream_logs; fi
        if [[ $TESTING_ENABLED == true ]] && [[ "${FUNCNAME[1]}" != "testFailureUponReceivingHTMLREsponse" ]]; then break; fi
        sleep "$STATUS_POLLING_INTERVAL"
    done
    if [ "$build_status" = 1 ]; then exit_code=0; else exit_code=1; fi
} 

function check_build_status() {
    local response=""
    local retry=3
        if [ -z "${TESTING_ENABLED}" ]; then
            local command="curl --silent -X GET -w \"status_code:%{http_code}\" https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug \
                --header 'Accept: application/json' --header 'Authorization: $ACCESS_TOKEN'"
            response=$(eval "${command}")
        else
            response=$(< ./testdata/"$1")
        fi
        [ "$DEBUG" == "true" ] && log "${command%%'--header'*}" "$response" "get_build_status.log"

        if [[ "$response" != *"<!DOCTYPE html>"* ]]; then
            handle_status_response "${response%'status_code'*}"
        else
            if [[ $status_counter -lt $retry ]]; then
                build_status=0
                ((status_counter++))
            else
                echo "ERROR: Invalid response received from Bitrise API"
                build_status="null" 
            fi
        fi
}

function handle_status_response() {
    local response="$1"
    local build_status_text=$(echo "$response" | jq ".data .status_text" | sed 's/"//g')
    if [ "$build_status_text" != "$current_build_status_text" ]; then
        echo "Build $build_status_text"
        current_build_status_text="${build_status_text}"
    fi
    build_status=$(echo "$response" | jq ".data .status")
}

function stream_logs() {
    local response=""
    local log_chunks_positions=()

    if [ -z "${TESTING_ENABLED}" ] ; then
        local command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug/log \
            --header 'Accept: application/json' --header 'Authorization: $ACCESS_TOKEN'"
        response=$(eval "$command")
    else
        response="$(< ./testdata/"$1"_log_info_response.json)"
    fi
    [ "$DEBUG" == "true" ] && log "${command%'--header'*}" "$response" "get_log_info.log"
    # Every chunk has an accompanying position. Storing the chunks' positions to track the chunks.
    while IFS='' read -r line; do log_chunks_positions+=("$line"); done < <(echo "$response" | jq ".log_chunks[].position")
    new_log_chunck_positions=()
    for i in "${log_chunks_positions[@]}"; do
        skip=
        for j in "${current_log_chunks_positions[@]}"; do
            [[ $i == "$j" ]] && { skip=1; break; }
        done
        [[ -z $skip ]] && new_log_chunck_positions+=("$i")
    done
    if [[ ${#new_log_chunck_positions[@]} != 0 ]]; then
        for i in "${new_log_chunck_positions[@]}"; do
            parsed_chunk=$(echo "$response" | jq --arg index "$i" '.log_chunks[] | select(.position == ($index | tonumber)) | .chunk')
            cleaned_chunk=$(echo "${parsed_chunk}" | sed -e 's/^"//' -e 's/"$//') 
            printf "%b" "$cleaned_chunk"
        done
    else
        return
    fi
    current_log_chunks_positions=("${log_chunks_positions[@]}")
}

function get_build_logs() {
    local log_is_archived=false
    local counter=0
    local retry=4
    local polling_interval=15
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
        echo "LOGS WERE NOT AVAILABLE - navigate to $build_url to see the logs."
        exit ${exit_code}
    else
        print_logs "$log_url"
    fi
}

function print_logs() {
    local url="$1"
    local logs=$(curl --silent -X GET "$url")

    echo "================================================================================"
    echo "============================== Bitrise Logs Start =============================="
    echo "$logs"
    echo "================================================================================"
    echo "==============================  Bitrise Logs End  =============================="

}

function build_status_message() {
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

function log() {
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
    validate_input
    trigger_build
    process_build
    [ -z "$STREAM" ] && get_build_logs 
    build_status_message "$build_status"
    exit ${exit_code}
fi