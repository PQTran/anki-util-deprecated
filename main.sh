#!/bin/bash

export HELPERS_DIR="helpers"
# shellcheck source=helpers/util_helper.sh
source "$HELPERS_DIR/util_helper.sh"
# shellcheck source=helpers/file_helper.sh
source "$HELPERS_DIR/file_helper.sh"
# shellcheck source=helpers/pinyin_helper.sh
source "$HELPERS_DIR/pinyin_helper.sh"
# shellcheck source=helpers/csv_helper.sh
source "$HELPERS_DIR/csv_helper.sh"
# shellcheck source=helpers/download_helper.sh
source "$HELPERS_DIR/download_helper.sh"

OUTPUT_DIR="output"
OUTPUT_AUDIO_DIR="$OUTPUT_DIR/audio"
OUTPUT_CSV_DIR="$OUTPUT_DIR/csv"
OUTPUT_LOG_DIR="$OUTPUT_DIR/logs"
export OUTPUT_SYLLABLE_CACHE="$OUTPUT_DIR/syllable.cache"

LOG_FILE="$OUTPUT_LOG_DIR/$(date).log"


# To do list:
# functions references files relative to directory is defined or not
# Cleanup last column in output, unless in debug mode
# validation page before downloading
# download_from_providers: check if a single provider covers all syllables
# download_audio_assets: error message on failed download
# google as audio provider for audio https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&q=%E4%B8%8D%E5%A5%BD%E6%84%8F%E6%80%9D&tl=zh-CN
# make all references to files relative to base of script
# properly close fd
function setup_output_dir {
    create_dir "$OUTPUT_DIR"
    create_dir "$OUTPUT_AUDIO_DIR"
    create_dir "$OUTPUT_CSV_DIR"
    create_dir "$OUTPUT_LOG_DIR"
    [[ -f "$OUTPUT_SYLLABLE_CACHE" ]] && rm "$OUTPUT_SYLLABLE_CACHE"
    touch "$OUTPUT_SYLLABLE_CACHE"
}

function handle_update_csv {
    local file=$1
    local updated_file

    updated_file="$(remove_template_row "$file" "$LOG_FILE")"
    updated_file="$(add_tone_sandhi_pinyin_column "$updated_file" "$LOG_FILE")"
    updated_file="$(update_pinyin_column "$updated_file" "$LOG_FILE")"

    echo "$updated_file"
}

function handle_create_audio {
    local file=$1

    download_audio_assets "$file" "$OUTPUT_AUDIO_DIR"
    combine_audio_assets "$file" "$OUTPUT_AUDIO_DIR" "$OUTPUT_AUDIO_DIR"
}

function handle_move_audio {
    local file=$1
    local updated_file

    # !!! remove hard coded + provide prompt w/ nav capabilities
    anki_audio_dir="../../.local/share/Anki2/pqtran/collection.media"

    # !!! update sound column regardless audio moved or not?
    updated_file="$(update_sound_column "$file" "$OUTPUT_AUDIO_DIR" "$LOG_FILE")"
    move_audio_assets "$updated_file" "$OUTPUT_AUDIO_DIR" "$anki_audio_dir"

    echo "$updated_file"
}

function anki-script-main {
    local input_file=$1
    local updated_file

    if ! [[ -f "$input_file" ]]; then
        echo "Input file does not exist."
        exit 1
    fi

    if ! [[ "$input_file" =~ \.csv$ ]]; then
        echo "Input file is not a .csv file."
        exit 1
    fi

    local input_file_name
    input_file_name="$(get_file_name "$input_file")"
    local temp_output_file="$OUTPUT_CSV_DIR/temp_$input_file_name"

    setup_output_dir

    copy_file "$input_file" "$temp_output_file"
    updated_file="$(handle_update_csv "$temp_output_file")"

    handle_create_audio "$updated_file"

    _get_user_response_move
    response=$?

    if [[ "$response" -eq 0 ]]; then
        updated_file="$(handle_move_audio "$updated_file")"
    fi

    # cleanup last column
    updated_file="$(remove_sandhi_column "$updated_file" "$LOG_FILE")"

    echo "Script is complete! Enjoy!"
}

# fd 3: reserved for reusable prompt functions
# fd 4: public functions consumed by main.sh
# fd 5: helpers of the public functions


# $1: input csv file
anki-script-main "$1"
