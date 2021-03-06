#!/bin/bash

function get_strict_file_name {
    local file=$1

    local file_name="$(get_file_name "$file")"

    [[ "$file_name" =~ ([^\.]*)\. ]]
    echo "${BASH_REMATCH[1]}"
}

# ex: ./file, dir/file, file, file.ext
function get_file_name {
    local file=$1

    local file_name
    if [[ "$file" =~ /([^/]*)$ ]]; then
        file_name="${BASH_REMATCH[1]}"
    else
        file_name="$file"
    fi

    echo "$file_name"
}

# ex: temp/test.csv, ../test.csv, test.csv
function get_file_dir_path {
    local file=$1

    local dir_path
    if [[ "$file" =~ (.*)/[^/]*$ ]]; then
        dir_path="${BASH_REMATCH[1]}"
    else
        dir_path="$(pwd)"
    fi

    echo "$dir_path"
}

function increment_file_name {
    local file=$1

    local file_name dir_path
    file_name="$(get_file_name "$file")"
    dir_path="$(get_file_dir_path "$file")"

    local index rest_file_name
    if [[ "$file_name" =~ ^([0-9]*)_(.*) ]]; then
        index="${BASH_REMATCH[1]}"
        index=$(("$index" + 1))

        rest_file_name="${BASH_REMATCH[2]}"
    else
        index="0"
        rest_file_name="$file_name"
    fi

    echo "$dir_path/$index""_$rest_file_name"
}

function create_dir {
    local directory=$1
    mkdir -p "$directory"
}

# precondition: input file exists
function copy_file {
    local input_file=$1
    local output_file=$2

    cp "$input_file" "$output_file"
}

function combine_pinyin_audio {
    local pinyin=$1
    local assets_dir=$2
    local output_dir=$3

    if [[ -z "$pinyin" ]] ||
           [[ -z "$assets_dir" ]] ||
           [[ -z "$output_dir" ]]; then
        return 1
    fi

    local success=0

    local audio_paths_file pinyin_syllables main_dir
    audio_paths_file="$(mktemp)"
    pinyin_syllables="$(get_pinyin_syllables "$pinyin")"
    main_dir="$(pwd)"

    local file_path tone
    while read -r syllable; do
        tone="$(get_tone "$syllable")"
        if [[ -z "$tone" ]] &&
               ! [[ -f "$main_dir/$assets_dir/$syllable.mp3" ]]; then
            syllable+="5"
        fi

        if ! [[ -f "$main_dir/$assets_dir/$syllable.mp3" ]]; then
            return 1
        fi

        # requires full path
        file_path="$main_dir/$assets_dir/$syllable.mp3"

        printf "file '%s'\n" "$file_path" >> "$audio_paths_file"
    done <<< "$pinyin_syllables"

    if [[ "$success" -eq 0 ]]; then
        ffmpeg -y -f concat -safe 0 -i "$audio_paths_file" -c copy "$output_dir/$pinyin.mp3"
    else
        echo "Was unable to combine: $pinyin" 1>&2
        return 1
    fi
}

function combine_audio_assets {
    local file=$1
    local assets_dir=$2
    local output_dir=$3

    create_dir "$output_dir"

    local sandhi_pinyin_values
    sandhi_pinyin_values="$(awk -F',' '{ print $7 }' "$file")"

    exec 4<&0
    while read -r -u 4 pinyin; do
        if [[ -f "$output_dir/$pinyin.mp3" ]]; then
            continue
        fi

        combine_pinyin_audio "$pinyin" "$assets_dir" "$output_dir"
    done 4<<< "$sandhi_pinyin_values"
    exec 4>&-
}

function move_audio_assets {
    local file=$1
    local audio_dir=$2
    local output_dir=$3

    local audio_files
    # removes [sound: and ]
    audio_files="$(awk -F',' '{ print substr($4, 8, length($4) - 8) }' "$file")"

    while read -r audio_file; do

        if [[ -n "$audio_file" ]]; then
            copy_file "$audio_dir/$audio_file" "$output_dir"
        fi

    done <<< "$audio_files"
}
