#!/bin/bash

# ex: ./file, dir/file, file
function get_filename {
    file=$1

    if [[ "$file" =~ /([^/]*)$ ]]; then
	file_name=${BASH_REMATCH[1]}
    else
	file_name=$file
    fi

    echo $file_name
}

function get_output_dir {
    output_dir="generated"

    echo $output_dir
}

function get_cache_audio_dir {
    output_dir=$(get_output_dir)
    cache_audio_dir=$output_dir"/audio"

    echo $cache_audio_dir
}

function get_cache_combined_audio_dir {
    cache_audio_dir=$(get_cache_audio_dir)
    cache_combined_audio_dir=$cache_audio_dir"/combined_audio"

    echo $cache_combined_audio_dir
}

function create_dir {
    directory=$1
    mkdir -p $directory
}

# precondition: input file exists
function copy_file {
    input_file=$1
    output_file=$2

    cp $input_file $output_file
}

function remove_template_row {
    input_file=$1
    output_file=$2
    temp_file=$(mktemp)

    template_row=0
    while IFS=',' read -r line; do
	if [[ $template_row -eq 0 ]]; then
	    let template_row+=1
	    continue
	fi

	echo $line >> $temp_file
    done < $input_file

    copy_file $temp_file $output_file
}

function combine_pinyin_audio {
    pinyin_word=$1
    audio_assets_dir=$2
    output_dir=$3

    temp_file=$(mktemp)

    combine_success=0
    while read -r syllable; do
	file_path=$(pwd)"/"$audio_assets_dir"/"$syllable".mp3"

	if ! [[ -f $file_path ]]; then
	    combine_success=1
	    break
	fi

	echo $(printf "file '%s'\n" $file_path) >> $temp_file
    done < <(get_pinyin_syllables $pinyin_word)

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

    while IFS=',' read -r col1 col2 col3 col4 col5 col6 audio_name; do
	combined_audio_dir=$(get_cache_combined_audio_dir)
	if [[ -f $combined_audio_dir"/"$audio_name".mp3" ]]; then
	    continue
	fi

	combine_pinyin_audio $audio_name $audio_assets_dir $output_dir
    done < $input_file
}

function move_audio_assets {
    csv_file=$1
    audio_dir=$2
    output_dir=$3

    while IFS=',' read -r col1 col2 col3 col4 col5 col6 audio_name; do
	if [[ -n $audio_name ]]; then
	    audio_file=$audio_name".mp3"
	    copy_file $audio_dir"/"$audio_name $output_dir"/"$audio_name
	fi
    done < $csv_file
}
