#!/bin/bash

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

    output_dir=$(get_output_dir $output_base_dir)
    output_csv_file=$output_dir"/"$input_file

    create_dir $output_dir
    copy_file $input_file $output_csv_file

}

# $1: input csv file
# $2: output directory
main $1 $2

