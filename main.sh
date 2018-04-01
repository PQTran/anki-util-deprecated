#!/bin/bash

source ./helpers/util_helper.sh
source ./helpers/file_helper.sh
source ./helpers/pinyin_helper.sh
source ./helpers/csv_helper.sh
source ./helpers/download_helper.sh


function combine_pinyin_audio {
    pinyin_word=$1
    audio_assets_dir=$2
    output_dir=$3

    temp_file=$(mktemp)

    combine_success=0

    while read -r -u8 syllable; do
	file_path=$(pwd)"/"$audio_assets_dir"/"$syllable".mp3"

	if ! [[ -f $file_path ]]; then
	    combine_success=1
	    break
	fi

	echo $(printf "file '%s'\n" $file_path) >> $temp_file
    done 8< <(get_pinyin_syllables $pinyin_word)

    if [[ $combine_success -eq 0 ]]; then
	ffmpeg -y -f concat -safe 0 -i $temp_file -c copy $output_dir"/"$pinyin_word".mp3"
    else
	echo "Was unable to combine: "$pinyin_word 1>&2
	return 1
    fi
}

function combine_audio_assets {
    input_file=$1
    audio_assets_dir=$2
    output_dir=$3

    create_dir $output_dir

    template_row=0

    while IFS=',' read -r -u3 col1 col2 col3 col4 col5 col6 col7; do
	if [[ $template_row -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

	combine_pinyin_audio $col7 $audio_assets_dir $output_dir

    done 3< $input_file
}
function anki-script-main {
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

    # for user prompts
    exec 3<&0
    input_filename=$(get_filename $input_file)
    output_dir=$(get_output_dir $output_base_dir)
    output_csv_file=$output_dir"/"$input_filename

    create_dir $output_dir
    remove_template_row $input_file $output_csv_file

    create_pinyin_syllables_column $output_csv_file
    update_reading_column $output_csv_file

    audio_assets_dir=$output_dir"/audio"
    download_audio_assets $output_csv_file $audio_assets_dir
    combined_audio_dir=$output_dir"/combined_audio"
    combine_audio_assets $output_csv_file $audio_assets_dir $combined_audio_dir
}

# $1: input csv file
# $2: output directory
anki-script-main $1 $2

