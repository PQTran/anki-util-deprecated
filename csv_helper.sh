#!/bin/bash

function get_updated_syllable {
    syllable=$1

    dominant_vowel=$(get_dominant_vowel $syllable)
    tone=$(get_tone $syllable)

    # trim tone
    syllable=$(echo $syllable | tr -d "1234")
    updated_syllable=$(transform_vowel $syllable $dominant_vowel $tone)
    echo $updated_syllable
}

function get_updated_reading_value {
    pinyin_word=$1

    result=""
    while read -r -u5 syllable; do
	result=$result$(get_updated_syllable $syllable)
    done 5< <(get_pinyin_syllables $pinyin_word)

    echo $result
}

function update_reading_column {
    csv_file=$1
    temp_file=$(mktemp)
    template_row=0

    while IFS=',' read -r -u4 col1 col2 rest; do
	if [[ $template_row -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

        reading_value=$(get_updated_reading_value $col2)

	echo $col1","$reading_value","$rest >> $temp_file
    done 4< $csv_file

    copy_file $temp_file $csv_file
}

# 3rd tone 3rd tone -> 2nd tone 3rd tone
function convert_reading_to_pronunciation {
    pinyin_word=$1

    result=""
    while read -r -u7 syllable; do
    	current=$syllable

    	if [[ "$current" =~ .*3$ ]] && [[ "$result" =~ (.*)3$ ]]; then
    	    result=${BASH_REMATCH[1]}"2"
    	fi

    	result=$result$current
    done 7< <(get_pinyin_syllables $pinyin_word)

    echo $result
}

function create_pronunciation_column {
    csv_file=$1
    temp_file=$(mktemp)
    template_row=0

    while IFS=',' read -r -u6 col1 col2 rest; do
	if [[ $template_row -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

	pronunciation_value=$(convert_reading_to_pronunciation $col2)

	echo $col1","$col2","$rest","$pronunciation_value >> $temp_file
    done 6< $csv_file

    copy_file $temp_file $csv_file
}

