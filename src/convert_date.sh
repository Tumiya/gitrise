#! /bin/bash 
# shellcheck disable=SC2120
# warning: function references arguments, but none are ever passed. 
# disabling because we are using optioanl parameters.

[ "$1" = "-t" ] && TESTING_ENABLED="true"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
   TZ="EST5EDT"
   DATE_CMD="date"
else
   DATE_CMD="gdate"
fi

# case "$OSTYPE" in 
#     "linux-gnu")
#         TZ="EST5EDT" date -d "$input_date"
#         ;;
#     "darwin"*)
#         if [ "$TEST_MODE" = "on" ]; then 
#             gdate -d "$input_date"
#         else 
#             #shellcheck disable=SC2078
#             [ dependency_is_installed ] && gdate -d "$input_date" || echo "Could not find gdate. Date conversion cannot happen without gdate." 
#         fi
#         ;;
#     *)
#         echo "date conversion is not supported for $OSTYPE operating system."  
#         ;;
# esac


convert_date(){
    if [ -n "$1" ]; then
        input_date=$1
        case "$OSTYPE" in
            "linux-gnu"|"darwin"*)
                $DATE_CMD -d "$input_date"
                ;;
            *)
                echo "date conversion is not supported for $OSTYPE operating system." 
                ;;
        esac
    else
        echo "Invalid input date"
    fi
}

dependency_is_installed(){
    if [ $TESTING_ENABLED = "true" ]; then 
        [ "$1" = "yes" ] && code=0 || code=1
    else
        command -v gdate > /dev/null
        code=$?
    fi

    if [[ $code != 0 ]]; then
        echo "gdate not found. You need gdate to get the proper date. To get it, you need to install coreutils. Would you like me to install it? (y/n)"
        [ $TESTING_ENABLED = "true" ] && response=$2 || response=$(read -r response)

        if [ "$response" = "y" ] || [ "$response" = "Y" ]; then 
            echo "installing coreutils"
            [ $TESTING_ENABLED != "true" ] && brew install coreutils
        else
            echo "permission denied to install coreutils."
            return 1    
        fi
    else
        return 0
    fi
}
# shellcheck disable=SC2119
# Use convert_date "$@" if function's $1 should mean script's $1.shellcheck(SC2119)
if [ "$0" = "${BASH_SOURCE[0]}" ] && [ -z "${TESTING_ENABLED}" ]; then
    convert_date "$@"
fi