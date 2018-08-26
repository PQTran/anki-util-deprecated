#!/bin/bash

source ./helpers/util_helper.sh
source ./helpers/file_helper.sh
source ./helpers/pinyin_helper.sh
source ./helpers/csv_helper.sh
source ./helpers/download_helper.sh

function anki-script-main {
    input_file=$1

    if [[ ! -f $input_file ]]; then
	echo "Input file does not exist."
	exit 1
    fi

    if ! [[ $input_file =~ \.csv$ ]]; then
	echo "Input file is not a .csv file."
	exit 1
    fi

    # for user prompts
    exec 3<&0
    input_filename=$(get_filename $input_file)
    output_dir=$(get_output_dir)
    output_csv_file=$output_dir"/"$input_filename

    create_dir $output_dir
    remove_template_row $input_file $output_csv_file

    create_pinyin_syllables_column $output_csv_file
    update_reading_column $output_csv_file

    audio_assets_dir=$output_dir"/audio"
    download_audio_assets $output_csv_file $audio_assets_dir
    combined_audio_dir=$audio_assets_dir"/combined_audio"
    combine_audio_assets $output_csv_file $audio_assets_dir $combined_audio_dir

    if $(_get_user_response_move); then
	# updates only if audio file exists
    	update_sound_column $output_csv_file $combined_audio_dir

	anki_output_dir="../../.local/share/Anki2/pqtran/collection.media"
	# moves all files specified from csv
    	move_audio_assets $output_csv_file $combined_audio_dir $anki_output_dir
    fi

    echo "Script is complete! Enjoy!"
}

# $1: input csv file
# $2: output directory
anki-script-main $1 $2

