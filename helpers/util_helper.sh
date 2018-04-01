#!/bin/bash

function replace_char {
    word=$1
    vowel=$2
    new_char=$3

    result=$(echo $word | sed -e "y/"$vowel"/"$new_char"/")
    echo $result
}

function _get_user_response_move {
    response=""
    until [[ "$response" =~ [ynN] ]]; do
    	read -u 3 -p "Move to Anki directory? [y/N]: " response
    done

    [[ "$response" =~ y ]]
}
