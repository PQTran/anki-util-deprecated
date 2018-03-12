#!/bin/bash

# precondition: / is in file path
# Ex: ./file or dir/file
function get_input_filename {
    input_file_path=$1

    [[ "$input_file_path" =~ /([^/]*)$ ]] && input_file=${BASH_REMATCH[1]}

    if [[ -z $input_file ]]; then
	input_file=$input_file_path
    fi

    echo $input_file
}

# default value: generated
# otherwise: add subdir generated to provided dir
function get_output_dir {
    output_base_dir=$1

    if [[ -z $output_base_dir ]]; then
	output_dir="generated"
    else
	# trim trailing /
	[[ "$output_base_dir" =~ ^(.*)/$ ]] && trimmed_dir=${BASH_REMATCH[1]}

	if [[ -z $trimmed_dir ]]; then
	    trimmed_dir=$output_base_dir
	fi

	output_dir=$trimmed_dir"/generated"
    fi

    echo $output_dir
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
