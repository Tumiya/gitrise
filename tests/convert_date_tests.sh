#! /bin/bash

# shellcheck disable=SC1091,SC2155
# Not following: (sourced file was not specified as input)
# Declare and assign separately to avoid masking return values.

source ./convert_date.sh -t

testNoInputDate(){
    local expected_response="no input date received"
    local actual=$(convert_date)
    assertEquals "Messages did not match" "$expected_response" "$actual"
}

testDateConversionOnInvalidOS(){
    local expected_message="date conversion is not supported for windows operating system."
    local actual_message=$(OSTYPE="windows" convert_date 2019-11-01T01:02:11Z)
    assertEquals "Messages did not match" "$expected_message" "$actual_message"
}

testDateConversionOnMac(){
    local expected_date="Thu Oct 31 21:02:11 EDT 2019"
    local actual_date=$(convert_date 2019-11-01T01:02:11Z)
    assertEquals "Dates did not match" "$expected_date" "$actual_date"
}

testDenyingInstallingDependency(){
    local message_1="gdate not found. You need gdate to get the proper date. To get it, you need to install coreutils. Would you like me to install it? (y/n)"
    local message_2="permission denied to install coreutils."
    local actual=$(dependency_is_installed "no" "n")
    assertContains "Messages did not match" "$actual" "$message_1"
    assertContains "Messages did not match" "$actual" "$message_2"
}

testAcceptingInstallingDependency(){
    local actual=$(dependency_is_installed "no" "y")
    local message_1="gdate not found. You need gdate to get the proper date. To get it, you need to install coreutils. Would you like me to install it? (y/n)"
    local message_2="installing coreutils"
    assertContains "Messages did not match" "$actual" "$message_1"
    assertContains "Messages did not match" "$actual" "$message_2"
}

. ./tests/shunit2
