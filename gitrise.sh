version="0.0.1"
app_name="Gitrise Trigger"

build_complete=0
build_output=""
build_index=0
build_slug=""

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
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
    -h|--help)
    usage
    shift;shift
    ;;
    *) usage
    POSITIONAL+=("$1");shift 
    ;;
esac
done
set -- "${POSITIONAL[@]}"

if [[ -z $WORKFLOW || -z $BRANCH || -z $PROJECT_SLUG || -z $ACCESS_TOKEN ]]; then
    echo "Please re-run -h or --help for help."
    exit 1
fi

usage() {
    echo ""
    echo "Usage: gitrise [options]"
    echo 
    echo "[options]"
    echo "  -w, --workflow      <string>    Bitrise Workflow"
    echo "  -b, --branch        <string>    Git Branch"
    echo "  -a, --access-token  <string>    Bitrise access token"
    echo "  -s, --slug          <string>    Bitrise project slug"
    echo "  -h, --help          <string>    Print this help text"
}

intro () {
    echo "$app_name version $version \nLaunched on $(date)"
}

pre_build () {  
    local __command="curl --silent -X POST https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds \
            --data '{\"hook_info\":{\"type\":\"bitrise\"},\"build_params\":{\"branch\":\"$BRANCH\",\"workflow_id\":\"$WORKFLOW\"}}' \
            --header 'Authorization: $ACCESS_TOKEN'"
    local __result=$(eval ${__command})
    local __build_url=$(echo ${__result} | jq ".build_url" | sed 's/"//g')
    build_slug=$(echo ${__result} | jq ".build_slug" | sed 's/"//g')
    echo "\nBuild URL: ${__build_url} \n\nHold on... We're about to liftoff! 🚀\n"
}

mid_build () {
    while [ "$build_complete" != "1" ]; do 
        local __command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug/log --header 'Authorization: $ACCESS_TOKEN'"
        local __next_output=$(eval ${__command} | jq ".log_chunks[0]" | jq ".chunk" | sed 's/"//g')
        local __next_index=$(eval ${__command} | jq ".log_chunks[0]" | jq ".position")
        local __new_chunks=${__next_output#${__build_output}}
        __command="curl --silent -X GET https://api.bitrise.io/v0.1/apps/$PROJECT_SLUG/builds/$build_slug --header 'Authorization: $ACCESS_TOKEN'"
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

intro
pre_build
mid_build
pst_build