#!/bin/bash
VERSION="0.3.0"
APP_NAME="Gitrise Trigger"

build_complete=0
build_output=""
build_index=0
build_slug=""

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
while [[ $# -gt 0 ]]; do
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

# if [[ -z $WORKFLOW || -z $BRANCH || -z $PROJECT_SLUG || -z $ACCESS_TOKEN ]]; then
#     echo "Please re-run -h or --help for help."
#     exit 1
# fi

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
    if [ "$TESTING_ENABLED" ]; then
        echo "Gitrise is running in testing mode"
    else
        printf "%s VERSION %s \nLaunched on $(date)" "$APP_NAME" "$VERSION"
    fi
}

pre_build () { 
    local result=""
    if [ ! "$TESTING_ENABLED" ]; then
        local environments=$(process_env_vars "$ENV_STRING")   
        local payload="{\"hook_info\":{\"type\":\"bitrise\"},\"build_params\":{\"branch\":\"$BRANCH\",\"workflow_id\":\"$WORKFLOW\",\"environments\":$environments \
        }}" 
        local command="curl --silent -X POST https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds \
                --data '$payload' \
                --header 'Authorization: $ACCESS_TOKEN'"
        result=$(eval "${command}")   
    else
        result=$(<./testdata/build_trigger_response.json)

    fi
    local build_url=$(echo "${result}" | jq ".build_url" | sed 's/"//g')
    build_slug=$(echo "${result}" | jq ".build_slug" | sed 's/"//g')
    printf "\nHold on... We're about to liftoff! 🚀\n \nBuild URL: %s" "${build_url}"
}

mid_build () {
    while [ "$build_complete" != "1" ]; do 
        local __command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug/log --header 'Authorization: $ACCESS_TOKEN'"
        local __next_output=$(eval ${__command} | jq ".log_chunks[0]" | jq ".chunk" | sed 's/"//g')
        local __next_index=$(eval ${__command} | jq ".log_chunks[0]" | jq ".position")
        local __new_chunks=${__next_output#${__build_output}}
        local __command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug --header 'Authorization: $ACCESS_TOKEN'"
        local __state=$(eval ${__command} | jq ".data" | jq ".status_text" | sed 's/"//g')
        if [ ${__state} != "in-progress" ]; then
            build_complete=1
        fi
        if [ "${__new_chunks}" = "null" ]; then
            echo "Waiting for worker... "
            sleep 1
        else
            if [ "$build_index" != "${__next_index}" ]; then
                printf -- "$(echo ${__new_chunks} | tr -d '%')"
                build_output=${__next_output}
                build_index=${__next_index}
            fi
            sleep 10
        fi
    done
}

pst_build () {
    local __command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug --header 'Authorization: $ACCESS_TOKEN'"
    local __state=$(eval ${__command} | jq ".data" | jq ".status")
    echo 
    echo 
    if [ "${__state}" -eq "0" ]; then 
        echo "Oh No! Build $build_slug has timed out! 😱"
        exit 1
    elif [ "${__state}" -eq "1" ]; then 
        echo "Build successful 🎉"
        exit 0
    elif [ "${__state}" -eq "2" ]; then 
        echo "Build Failed 🚨"
        exit 1
    elif [ "${__state}" -eq "3" ]; then 
        echo "Build Aborted 💥"
        exit 1
    fi
}

# No function execution when the script is sourced 
if [ "$0" = "$BASH_SOURCE" ] && [ -z "${TESTING_ENABLED}" ]; then
    intro
    pre_build
    mid_build
    pst_build
fi