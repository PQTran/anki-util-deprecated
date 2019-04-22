#!/bin/bash

if [[ -n "$HELPERS_DIR" ]]; then
    # shellcheck source=./file_helper.sh
    source "$HELPERS_DIR/file_helper.sh"
    # shellcheck source=./util_helper.sh
    source "$HELPERS_DIR/util_helper.sh"
    # shellcheck source=./pinyin_helper.sh
    source "$HELPERS_DIR/pinyin_helper.sh"
else
    source "./file_helper.sh"
    source "./util_helper.sh"
    source "./pinyin_helper.sh"
fi

function remove_template_row {
    local file=$1
    local log_file=$2
    local result=""

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "remove_template_row" "$log_file"

    local template_row=0
    while read -r line; do
	if [[ "$template_row" -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

        if [[ -z "$result" ]]; then
            result="$line"
        else
            result="$result\n$line"
        fi
    done < "$file"

    echo -e "$result" > "$updated_file"
    echo "$updated_file"
}

function _get_updated_syllable {
    local syllable=$1

    local dominant_vowel tone
    dominant_vowel="$(get_dominant_vowel "$syllable")"
    tone="$(get_tone "$syllable")"

    local updated_syllable
    updated_syllable="$(update_pinyin "$syllable" "$dominant_vowel" "$tone")"

    echo "$updated_syllable"
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
    exec 5>&-

    echo "$result"
}

function update_pinyin_column {
    local file=$1
    local log_file=$2
    local result=""

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "update_pinyin_column" "$log_file"

    exec 6<&0
    local updated_pinyin
    while IFS=',' read -r -u 6 char_col pinyin_col rest; do
        updated_pinyin="$(_get_updated_pinyin_value "$pinyin_col")"

        updated_line="$char_col,$updated_pinyin,$rest"
        if [[ -z "$result" ]]; then
            result="$updated_line"
        else
            result="$result\n$updated_line"
        fi
    done 6< "$file"
    exec 6>&-

    echo -e "$result" > "$updated_file"
    echo "$updated_file"
}

# converts: 3rd tone 3rd tone -> 2nd tone 3rd tone
function _apply_tone_sandhi {
    local pinyin_word=$1
    local result=""

    local pinyin_syllables
    pinyin_syllables="$(get_pinyin_syllables "$pinyin_word")"

    while read -r syllable; do
    	if [[ $(get_tone "$result") -eq 3 ]] &&
               [[ $(get_tone "$syllable") -eq 3 ]]; then
            result="${result::-1}2"
    	fi

    	result="$result$syllable"
    done <<< "$pinyin_syllables"

    echo "$result"
}

function add_tone_sandhi_pinyin_column {
    local file=$1
    local log_file=$2
    local result=""

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "create_pinyin_syllables_column" "$log_file"

    exec 5<&0
    local updated_pinyin_col
    while IFS=',' read -r -u 5 char_col pinyin_col rest; do
	if [[ -z "$char_col" ]] ||
	       [[ -z "$pinyin_col" ]]; then
	    continue
	fi

	updated_pinyin_col="$(_apply_tone_sandhi "$pinyin_col")"

	updated_line="$char_col,$pinyin_col,$rest,$updated_pinyin_col"

        if [[ -z "$result" ]]; then
            result="$updated_line"
        else
            result="$result\n$updated_line"
        fi
    done 5< "$file"
    exec 5>&-

    echo -e "$result" > "$updated_file"
    echo "$updated_file"
}

function update_sound_column {
    local file=$1
    local audio_dir=$2
    local log_file=$3
    local result=""

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "update_sound_column" "$log_file"

    local audio_file updated_line
    while read -r line; do
        audio_file="$(echo "$line" | awk -F',' '{ print $7".mp3" }')"

        if [[ -f "$audio_dir/$audio_file" ]]; then
            updated_line="$(echo "$line" |
                awk -F',' -v sound_col="$audio_file" \
                    '{ print $1","$2","$3",[sound:"sound_col"],"$5","$6","$7 }')"
        else
            updated_line="$line"
        fi

        if [[ -z "$result" ]]; then
            result="$updated_line"
        else
            result="$result\n$updated_line"
        fi

    done < "$file"

    echo -e "$result" > "$updated_file"
    echo "$updated_file"
}

function remove_sandhi_column {
    local file=$1
    local log_file=$2
    local result=""

    local updated_file
    updated_file="$(increment_file_name "$file")"
    _log_action "$updated_file" "remove_sandhi_column" "$log_file"

    local updated_line
    exec 6<&0
    while IFS=',' read -r -u 6 line; do
        updated_line="$(echo "$line" |
                           awk -F',' '{ print $1","$2","$3","$4","$5","$6 }')"

        if [[ -z "$result" ]]; then
            result="$updated_line"
        else
            result="$result\n$updated_line"
        fi
    done 6< "$file"
    exec 6>&-

    echo -e "$result" > "$updated_file"
    echo "$updated_file"
}