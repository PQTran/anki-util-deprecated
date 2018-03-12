#!/bin/bash

function replace_char {
    word=$1
    vowel=$2
    new_char=$3

    result=$(echo $word | sed -e "y/"$vowel"/"$new_char"/")
    echo $result
}

