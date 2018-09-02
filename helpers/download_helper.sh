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



function validate_url {
    local url=$1

    local response
    response="$(wget -S --spider "$url" 2>&1)"

    case "$response" in
        # must be first because of redirection then ok responses
        *'HTTP/1.1 302 Found'*)
            return 1
            ;;
        *'HTTP/1.1 200 OK'*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

function download_from_providers {
    local syllable=$1
    local output_dir=$2

    local audio_providers="config/audio_providers.config"
    local audio_file="$syllable.mp3"

    exec 5<&0
    local audio_url
    while read -r -u 5 line; do
	if [[ "$line" =~ ^\+(.*) ]]; then
	    audio_url="${BASH_REMATCH[1]}/$audio_file"

	    if validate_url "$audio_url"; then
	        wget -nv -O "$output_dir/$audio_file" "$audio_url" && break
	    fi
	fi
    done 5< "$audio_providers"
}

function _download_syllable {
    local syllable=$1
    local output_dir=$2

    if [[ -f "$output_dir/$syllable.mp3" ]]; then
        return 0
    fi

    download_from_providers "$syllable" "$output_dir"
    result=$?

    if [ "$result" -eq 0 ] && [[ -z "$(get_tone "$syllable")" ]]; then
        download_from_providers "$syllable""5" "$output_dir"
    fi
}

function download_audio_assets {
    local file=$1
    local output_dir=$2

    create_dir "$output_dir"

    local sandhi_pinyin_values
    sandhi_pinyin_values="$(awk -F',' '{ print $7 }' "$file")"

    exec 4<&0
    local pinyin_syllables
    while read -r pinyin; do
        pinyin_syllables="$(get_pinyin_syllables "$pinyin")"

        while read -r -u 4 syllable; do
            _download_syllable "$syllable" "$output_dir"
        done 4<<< "$pinyin_syllables"

    done <<< "$sandhi_pinyin_values"
}
