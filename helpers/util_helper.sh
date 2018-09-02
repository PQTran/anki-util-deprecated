#!/bin/bash

function replace_char {
    local word=$1
    local vowel=$2
    local new_char=$3

    local result
    result=$(echo "$word" | sed -e "y/$vowel/$new_char/")

    echo "$result"
}

function _get_user_response_move {
    local response=""

    exec 3<&0
    until [[ "$response" =~ [ynN] ]]; do
    	read -r -u 3 -p "Move to Anki directory? [y/N]: " response
    done

    [[ "$response" =~ y ]]
}

function _log_action {
    local file=$1
    local action=$2
    local log_file=$3

    if [[ -n "$log_file" ]]; then
        echo "$file: $action" >> "$log_file"
    fi
}