#!/bin/bash

function validate_url {
    url=$1

    response=$(wget -S --spider $url 2>&1)

    # necessary to check this condition or can we consolidate to else branch
    if [[ $(echo $response | grep -c 'HTTP/1.1 302 Found') -ge 1 ]]; then
	return 1
    fi

    if [[ $(echo $response | grep -c 'HTTP/1.1 200 OK') -ge 1 ]]; then
	return 0
    else
	return 1
    fi
}

function download_from_providers {
    syllable=$1
    output_dir=$2
    audio_file=$syllable".mp3"
    audio_providers="config/audio_providers.config"

    while read line; do
	if [[ "$line" =~ ^\+(.*) ]]; then
	    provider_url=${BASH_REMATCH[1]}
	    output_file=$output_dir"/"$audio_file
	    audio_url=$provider_url$audio_file

	    if $(validate_url $audio_url); then
		wget -nv -O $output_file $audio_url && break
	    fi
	fi
    done < $audio_providers
}

function download_audio_assets {
    input_file=$1
    output_dir=$2

    create_dir $output_dir

    while IFS=',' read -r col1 col2 col3 col4 col5 col6 col7; do

	while read -r syllable; do
	    if [[ -f "generated/audio/"$syllable".mp3" ]]; then
	    	continue
	    fi

	    if ! $(download_from_providers $syllable $output_dir); then

		if [[ -z $(get_tone $syllable) ]]; then
		    download_from_providers $syllable"5" $output_dir
		    continue
		fi

		# unable to download syllable, therefore skip word
		break;
	    fi
	done < <(get_pinyin_syllables $col7)

    done < $input_file
}
