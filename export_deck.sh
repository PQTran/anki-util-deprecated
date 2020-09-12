#!/bin/bash

export HELPERS_DIR="helpers"
# shellcheck source=helpers/file_helper.sh
source "$HELPERS_DIR/file_helper.sh"

OUTPUT_DIR="output"
OUTPUT_EXPORTED_DECKS="$OUTPUT_DIR/exported_decks"

function setup_output_dir {
    create_dir "$OUTPUT_DIR"
    create_dir "$OUTPUT_EXPORTED_DECKS"
}

function transform_deck {
    local deck=$1
    local output_file=$2

    local line_num=0
    local traditional reading meaning notes
    exec 3<&0
    while read -r -u 3 line; do
        let line_num+=1
        if [[ $(( $line_num % 3 )) -eq 1 ]]; then
            # traditional char
            [[ "$line" =~ class\=chinese\>([^\<]*)\<  ]]
            traditional="${BASH_REMATCH[1]}"

            # reading
            [[ "$line" =~ sound:([^\.]*)\.mp3 ]]
            reading="${BASH_REMATCH[1]}"

            # meaning
            [[ "$line" =~ class\=meaning\>([^\<]*)\< ]]
            meaning="${BASH_REMATCH[1]}"

            # notes
            [[ "$line" =~ class\=notes\>([^\<]*)\< ]]
            notes="${BASH_REMATCH[1]}"

            echo "$traditional,$reading,$meaning,,,$notes" >> "$output_file"
        fi
    done 3< "$deck"
}

function main {
    local deck=$1
    local template_file="$HELPERS_DIR/deck-template.csv"

    if [[ ! -f "$deck" ]]; then
        echo "File does not exist" 1>&2
        exit 1
    fi

    setup_output_dir

    output_file="$OUTPUT_EXPORTED_DECKS/$(get_strict_file_name "$deck").csv"
    copy_file "$template_file" "$output_file"

    transform_deck "$deck" "$output_file"
}

main "$1"
