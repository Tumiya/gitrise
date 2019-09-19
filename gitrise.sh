#!/bin/bash
VERSION="0.4.0"
APP_NAME="Gitrise Trigger"

build_slug=""
build_url=""
build_status=0
previous_build_status_text=""
exit_code=""
log_url=""

usage() {
    echo ""
    echo "Usage: gitrise [options]"
    echo 
    echo "[options]"
    echo "  -w, --workflow      <string>    Bitrise Workflow"
    echo "  -b, --branch        <string>    Git Branch"
    echo "  -e, --env           <string>    List of environment variables in the form of key1:value1,key2:value2"
    echo "  -a, --access-token  <string>    Bitrise access token"
    echo "  -s, --slug          <string>    Bitrise project slug"
    echo "  -h, --help          <string>    Print this help text"
}

# parsing space separated options
POSITIONAL=()
while [ $# -gt 0 ]; do
    key="$1"
    case $key in
    -v|--version)
        echo "Trigger version $VERSION"
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
    *) 
        echo "Invalid option '$1'"
        usage
        POSITIONAL+=("$1")
        exit 1
    ;;
    esac
done

# restore positional parameters
set -- "${POSITIONAL[@]}"

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
        IFS=':' read -a array_from_pair <<< "$i"
        key="${array_from_pair[0]}"
        value="${array_from_pair[1]}"
        result+="{\"mapped_to\":\"$key\",\"value\":\"$value\",\"is_expand\":true},"
    done
    echo "[$(sed 's/,$//' <<< $result)]"
}

intro () {
    if [ "${TESTING_ENABLED}" = "true" ]; then
        echo "Gitrise is running in testing mode"
    else
        printf "%s VERSION %s \nLaunched on $(date)\n" "$APP_NAME" "$VERSION"
    fi
}
# shellcheck disable=SC2120
trigger_build () { 
    local result=""
    if [ -z "${TESTING_ENABLED}" ]; then
        local environments=$(process_env_vars "$ENV_STRING")   
        local payload="{\"hook_info\":{\"type\":\"bitrise\"},\"build_params\":{\"branch\":\"$BRANCH\",\"workflow_id\":\"$WORKFLOW\",\"environments\":$environments \
        }}" 
        local command="curl --silent -X POST https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds \
                --data '$payload' \
                --header 'Authorization: $ACCESS_TOKEN'"
        result=$(eval "${command}") 
    else
        result=$(<./testdata/$1_build_trigger_response.json)
    fi
    status=$(echo "$result" | jq ".status" | sed 's/"//g' ) 
    if [ "$status" != "ok" ]; then
        msg=$(echo "$result" | jq ".message" | sed 's/"//g')
        echo "ERROR: $msg"
        exit 1
    else 
        build_url=$(echo "$result" | jq ".build_url" | sed 's/"//g')
        build_slug=$(echo "$result" | jq ".build_slug" | sed 's/"//g')
    fi
    printf "\nHold on... We're about to liftoff! 🚀\n \nBuild URL: %s\n" "${build_url}"
}

get_build_status () {
    local response=""
    while [ "${build_status}" = 0 ]; do
        if [ -z "${TESTING_ENABLED}" ]; then
            sleep 10
            local command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug --header 'Authorization: $ACCESS_TOKEN'"
            response=$(eval "${command}")
        else
            response=$(< ./testdata/build_status_response.json)
        fi
        local current_build_status_text=$(echo "$response" | jq ".data .status_text" | sed 's/"//g')
        if [ "$previous_build_status_text" != "$current_build_status_text" ]; then
            echo "Build $current_build_status_text"
            previous_build_status_text="${current_build_status_text}"
        fi
        build_status=$(echo "$response" | jq ".data .status")
    done

    if [ "$build_status" = 1 ]; then exit_code=0; else exit_code=1; fi
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

# shellcheck disable=SC2120
get_log_info(){
    local log_is_archived=false
    local counter=0
    local retry=4
    local polling_interval=5
    local response=""
    while ! "$log_is_archived"  && [[ "$counter" -lt "$retry" ]]; do
        if [ -z "${TESTING_ENABLED}" ] ; then
            sleep "$polling_interval"
            local command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug/log --header 'Authorization: $ACCESS_TOKEN'"
            response=$(eval "$command")
        else
            response="$(< ./testdata/$1_log_info_response.json)"
        fi
        log_is_archived=$(echo "$response" | jq ".is_archived")
        ((counter++))
    done
    log_url=$(echo "$response" | jq ".expiring_raw_log_url" | sed 's/"//g')
    if ! "$log_is_archived" || [ -z "$log_url" ]; then
        echo "LOGS WERE NOT AVAILABLE - go to $build_url to see log."
        exit ${exit_code}
    fi
}

get_logs(){
    local url="$1"
    local logs=$(curl --silent -X GET "$url")

    echo "================================================================================"
    echo "============================== Bitrise Logs Start =============================="
    echo "$logs"
    echo "================================================================================"
    echo "==============================  Bitrise Logs End  =============================="

}
# No function execution when the script is sourced 
if [ "$0" = "$BASH_SOURCE" ] && [ -z "${TESTING_ENABLED}" ]; then
    intro
    trigger_build
    get_build_status
    get_log_info
    get_logs "$log_url"
    build_status_message "$build_status"
    exit ${exit_code}
fi
