#!/bin/bash

if [[ -n "$HELPERS_DIR" ]]; then
    # shellcheck source=./file_helper.sh
    source "$HELPERS_DIR/file_helper.sh"
    # shellcheck source=./util_helper.sh
    source "$HELPERS_DIR/util_helper.sh"
else
    source "./file_helper.sh"
    source "./util_helper.sh"
fi

function remove_template_row {
    local file=$1
    local log_file=$2

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "remove_template_row" "$log_file"

    local template_row=0
    while read -r line; do
	if [[ "$template_row" -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

	echo "$line" >> "$updated_file"
    done < "$file"

    echo "$updated_file"
}

function _get_updated_syllable {
    local syllable=$1

    local dominant_vowel tone
    dominant_vowel="$(get_dominant_vowel "$syllable")"
    tone="$(get_tone "$syllable")"

    if [[ -n "$dominant_vowel" ]] &&
	   [[ -n "$tone" ]]; then
	# trim tone
        syllable="$(echo "$syllable" | tr -d "1234")"
        syllable="$(transform_vowel "$syllable" "$dominant_vowel" "$tone")"
    fi

    echo "$syllable"
}

function _get_updated_pinyin_value {
    local word=$1
    local result=""

    exec 5<&0
    local pinyin_syllables
    pinyin_syllables="$(get_pinyin_syllables "$word")"
    while read -r -u 5 syllable; do
    	result="$result$(_get_updated_syllable "$syllable")"
    done 5<<< "$pinyin_syllables"

    echo "$result"
}

function update_pinyin_column {
    local file=$1
    local log_file=$2

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "update_pinyin_column" "$log_file"

    exec 6<&0
    local updated_pinyin
    while IFS=',' read -r -u 6 char_col pinyin_col rest; do
        updated_pinyin="$(_get_updated_pinyin_value "$pinyin_col")"
        echo "$char_col,$updated_pinyin,$rest" >> "$updated_file"
    done 6< "$file"

    echo "$updated_file"
}

# converts: 3rd tone 3rd tone -> 2nd tone 3rd tone
function _apply_tone_sandhi {
    local pinyin_word=$1
    local result=""

    local pinyin_syllables
    pinyin_syllables="$(get_pinyin_syllables "$pinyin_word")"

    exec 4<&0
    while read -r -u 4 syllable; do
    	if [[ "$result" =~ (.*)3$ ]] && [[ "$syllable" =~ .*3$ ]]; then
    	    result="${BASH_REMATCH[1]}2"
    	fi

    	result="$result$syllable"
    done 4<<< "$pinyin_syllables"

    echo "$result"
}

function add_tone_sandhi_pinyin_column {
    local file=$1
    local log_file=$2

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "create_pinyin_syllables_column" "$log_file"

    local updated_pinyin_col original_line
    while IFS=',' read -r char_col pinyin_col rest; do
	if [[ -z "$char_col" ]] ||
	       [[ -z "$pinyin_col" ]]; then
	    continue
	fi

	updated_pinyin_col="$(_apply_tone_sandhi "$pinyin_col")"

	original_line="$char_col,$pinyin_col,$rest"
	echo "$original_line,$updated_pinyin_col" >> "$updated_file"
    done < "$file"

    echo "$updated_file"
}

function update_sound_column {
    local file=$1
    local audio_dir=$2
    local log_file=$3

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "update_sound_column" "$log_file"

    local audio_file
    while read -r line; do
        audio_file="$(echo "$line" | awk -F',' '{ print $7".mp3" }')"

        if [[ -f "$audio_dir/$audio_file" ]]; then
            echo "$line" |
                awk -F',' -v sound_col="$audio_file" \
                    '{ print $1,$2,$3,sound_col,$5,$6,$7 }' \
                    >> "$updated_file"
        else
            echo "$line" >> "$updated_file"
        fi

    done < "$file"

    echo "$updated_file"
}
