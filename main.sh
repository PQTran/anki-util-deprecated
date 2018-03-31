#!/bin/bash

source ./helpers/util_helper.sh
source ./helpers/file_helper.sh
source ./helpers/pinyin_helper.sh
source ./helpers/csv_helper.sh


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

function validate_url {
    url=$1

    response=$(wget -S --spider $url 2>&1)

    if [[ $(echo $response | grep -c 'HTTP/1.1 302 Found') -ge 1 ]]; then
	return 1
    fi

    if [[ $(echo $response | grep -c 'HTTP/1.1 200 Found') -ge 1 ]]; then
	return 1
    else
	return 0
    fi
}

function download_from_providers {
    syllable=$1
    output_dir=$2
    audio_file=$syllable".mp3"
    audio_providers="config/audio_providers.config"

    while read -u9 line; do
	if [[ "$line" =~ ^\+(.*) ]]; then
	    provider_url=${BASH_REMATCH[1]}
	    output_file=$output_dir"/"$audio_file
	    audio_url=$provider_url$audio_file

	    if $(validate_url $audio_url); then
		wget -nv -O $output_file $audio_url && break
	    fi
	fi
    done 9< $audio_providers
}

function download_audio_assets {
    input_file=$1
    output_dir=$2

    create_dir $output_dir

    template_row=0

    while IFS=',' read -r -u3 col1 col2 col3 col4 col5 col6 col7; do
	if [[ $template_row -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

	while read -r -u8 syllable; do
	    if ! $(download_from_providers $syllable $output_dir); then

		if [[ -z $(get_tone $syllable) ]]; then
		    download_from_providers $syllable"5" $output_dir
		    continue
		fi

		# skip word if unable to download it's component
		# in future sections, if unable to find the needed filed
		# we continue to skip
		break;
		# action
	    fi
	done 8< <(get_pinyin_syllables $col7)

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

    input_filename=$(get_filename $input_file)
    output_dir=$(get_output_dir $output_base_dir)
    output_csv_file=$output_dir"/"$input_filename

    create_dir $output_dir
    copy_file $input_file $output_csv_file

    # todo: implement logic
    create_pronunciation_column $output_csv_file
    update_reading_column $output_csv_file

    # want some helper functions to loop syllables, pinyin_helper
    audio_assets_dir=$output_dir"/audio"
    download_audio_assets $output_csv_file $audio_assets_dir
    combined_audio_dir=$output_dir"/combined_audio"
    combine_audio_assets $output_csv_file $audio_assets_dir $combined_audio_dir
}

# $1: input csv file
# $2: output directory
anki-script-main $1 $2

