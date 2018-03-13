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
    pinyin_syllables=$1

    # processes n-1 syllables
    while [[ "$pinyin_syllables" =~ (^[^0-9]*[0-9])(.+) ]]; do
	syllable=${BASH_REMATCH[1]}
	result=$result$(get_updated_syllable $syllable)

        pinyin_syllables=${BASH_REMATCH[2]}
    done

    # nth syllable
    syllable=$pinyin_syllables
    result=$result$(get_updated_syllable $syllable)

    echo $result
}

function update_reading_column {
    csv_file=$1
    temp_file=$(mktemp)
    template_row=0

    while IFS=',' read -r col1 col2 rest; do
	if [[ $template_row -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

        reading_value=$(get_updated_reading_value $col2)

	echo $col1","$reading_value","$rest >> $temp_file
    done <$csv_file

    copy_file $temp_file $csv_file
}

# !!! TODO
# 3rd tone 3rd tone -> 2nd tone 3rd tone
# yi1 xx4 -> yi2 xx4
# yi1 xx1/2/3 -> yi4 xx1/2/3
function convert_reading_to_pronunciation {
    reading_cell=$1

    echo $reading_cell
}

function create_pronunciation_column {
    csv_file=$1
    temp_file=$(mktemp)
    template_row=0

    while IFS=',' read -r col1 col2 rest; do
	if [[ $template_row -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

	pronunciation_value=$(convert_reading_to_pronunciation $col2)

	echo $col1","$col2","$rest","$pronunciation_value >> $temp_file
    done <$csv_file

    copy_file $temp_file $csv_file
}
