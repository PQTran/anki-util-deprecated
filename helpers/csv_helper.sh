#!/bin/bash

function _get_updated_syllable {
    syllable=$1
    updated_syllable=$syllable

    dominant_vowel=$(get_dominant_vowel $syllable)
    tone=$(get_tone $syllable)

    if [[ -n $dominant_vowel ]] &&
	   [[ -n $tone ]]; then
	# trim tone
	updated_syllable=$(echo $updated_syllable | tr -d "1234")
	updated_syllable=$(transform_vowel $updated_syllable $dominant_vowel $tone)
    fi

    echo $updated_syllable
}

function _get_updated_reading_value {
    pinyin_word=$1

    result=""
    while read -r syllable; do
    	result=$result$(_get_updated_syllable $syllable)
    done < <(get_pinyin_syllables $pinyin_word)

    echo $result
}

function update_reading_column {
    csv_file=$1
    temp_file=$(mktemp)

    while IFS=',' read -r col1 col2 rest; do
        reading_value=$(_get_updated_reading_value $col2)

	echo $col1","$reading_value","$rest >> $temp_file
    done < $csv_file

    copy_file $temp_file $csv_file
}

# converts: 3rd tone 3rd tone -> 2nd tone 3rd tone
function _get_pinyin_syllables_value {
    pinyin_word=$1

    result=""
    while read -r syllable; do
    	current=$syllable

    	if [[ "$current" =~ .*3$ ]] && [[ "$result" =~ (.*)3$ ]]; then
    	    result=${BASH_REMATCH[1]}"2"
    	fi

    	result=$result$current
    done < <(get_pinyin_syllables $pinyin_word)

    echo $result
}

function create_pinyin_syllables_column {
    csv_file=$1
    temp_file=$(mktemp)

    while IFS=',' read -r col1 col2 rest; do
	if [[ -z $col1 ]] ||
	       [[ -z $col2 ]]; then
	    continue
	fi

	pinyin_syllables_value=$(_get_pinyin_syllables_value $col2)

	main_cols=$col1","$col2","$rest
	echo $main_cols","$pinyin_syllables_value >> $temp_file
    done < $csv_file

    copy_file $temp_file $csv_file
}

