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

# default return value: generated
# add subdir generated to provided dir
function get_output_dir {
    output_base_dir=$1

    if [[ -z $output_base_dir ]]; then
	output_dir="generated"
    else
	# trim trailing /
	if [[ "$output_base_dir" =~ ^(.*)/$ ]]; then
	    output_dir=${BASH_REMATCH[1]}
	else
	    output_dir=$output_base_dir
	fi

	output_dir=$output_dir"/generated"
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
