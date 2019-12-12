#! /bin/bash

# text="azi"
# message="curl --silent -X POST https://api.bitrise.io/v0.1/apps/52729494c71c6882/builds"
# echo "$message"
# temp=${message/%\/'apps'*\/'builds'/\/'apps'\/'***'\/'builds'}
# echo "temp: $temp"
# # a=$(echo "{$message}" | tr  \" \')


######
#         com1="${command%'--data'*}"
#         echo "COM: $com1"
#         tempi=${com1/%\/'apps'*\/'builds'/\/'apps'\/'***'\/'builds'}
#          echo "temp: $tempi" 
#          log "${command%'--data'*}" "$result"       
#          exit 1
# ####

#     printf "%b" "REQUEST:$request\n\nRESPONSE:$response\n\n" >> gitrise.log

CI_MERGE_REQUEST_TARGET_BRANCH_NAME="$1"
ENABLE_CODE_COVERAGE=false

echo "target: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME"

if [[ "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME" == hotfix\/* ]]; then ENABLE_CODE_COVERAGE=false; else ENABLE_CODE_COVERAGE=true; fi

echo "coverage: $ENABLE_CODE_COVERAGE"
