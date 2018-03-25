#!/bin/bash

source ./util_helper.sh
source ./file_helper.sh
source ./pinyin_helper.sh
source ./csv_helper.sh

function main {
    input_file=$1
    output_base_dir=$2

    if [[ ! -f $input_file ]]; then
	echo "Input file does not exist."
	exit 1
    fi

    if [[ ! "$input_file" =~ \.csv$ ]]; then
	echo "Input file is not a .csv file."
	exit 1
    fi

    input_filename=$(get_filename $input_file)
    output_dir=$(get_output_dir $output_base_dir)
    output_csv_file=$output_dir"/"$input_filename

    create_dir $output_dir
    copy_file $input_file $output_csv_file

    # todo: implement logic
    create_pronunciation_column $output_csv_file
    update_reading_column $output_csv_file

    # want some helper functions to loop syllables, pinyin_helper
    # download_audio_assets $output_csv_file
    # combine_audio_assets $output_csv_file
    # update_sound_column $ouput_csv_file
    # move_audio_assets
}

# $1: input csv file
# $2: output directory
main $1 $2

