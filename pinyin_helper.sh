#!/bin/bash

# v -> ü
function transform_vowel {
    word=$1
    vowel=$2
    tone=$3

    case $vowel in
	a)
	    case $tone in
		1)
		    new_char="ā"
		    ;;
		2)
		    new_char="á"
		    ;;
		3)
		    new_char="ă"
		    ;;
		4)
		    new_char="à"
		    ;;
	    esac
	    ;;
	o)
	    case $tone in
		1)
		    new_char="ō"
		    ;;
		2)
		    new_char="ó"
		    ;;
		3)
		    new_char="ǒ"
		    ;;
		4)
		    new_char="ò"
		    ;;
	    esac
	    ;;
	e)
	    case $tone in
		1)
		    new_char="ē"
		    ;;
		2)
		    new_char="é"
		    ;;
		3)
		    new_char="ě"
		    ;;
		4)
		    new_char="è"
		    ;;
	    esac
	    ;;
	i)
	    case $tone in
		1)
		    new_char="ī"
		    ;;
		2)
		    new_char="í"
		    ;;
		3)
		    new_char="ĭ"
		    ;;
		4)
		    new_char="ì"
		    ;;
	    esac
	    ;;
	u)
	    case $tone in
		1)
		    new_char="ū"
		    ;;
		2)
		    new_char="ú"
		    ;;
		3)
		    new_char="ŭ"
		    ;;
		4)
		    new_char="ù"
		    ;;
	    esac
	    ;;
	v)
	    case $tone in
		1)
		    new_char="ǖ"
		    ;;
		2)
		    new_char="ǘ"
		    ;;
		3)
		    new_char="ǚ"
		    ;;
		4)
		    new_char="ǜ"
		    ;;
	    esac
	    ;;
    esac

    result=$(replace_char $word $vowel $new_char)
    echo $result
}

# aoeiuv
# iu or ui makes the second vowel accented
function get_dominant_vowel {
    string=$1

    case $string in
	*a*)
	    echo "a"
	    ;;
	*o*)
	    echo "o"
	    ;;
	*e*)
	    echo "e"
	    ;;
	*ui*)
	    echo "i"
	    ;;
	*iu*)
	    echo "u"
	    ;;
	*i*)
	    echo "i"
	    ;;
	*u*)
	    echo "u"
	    ;;
	*ü*)
	    echo "ü"
	    ;;
	# *) log error
    esac
}

function get_tone {
    pinyin_syllable=$1

    case $pinyin_syllable in
	*1)
	    echo "1"
	    ;;
	*2)
	    echo "2"
	    ;;
	*3)
	    echo "3"
	    ;;
	*4)
	    echo "4"
	    ;;
	# *)
	#     echo "5"
    esac
}

function get_pinyin_initials {
    pinyin_initials=$(cat pinyin-initials.txt)
    echo $pinyin_initials
}

function get_strict_pinyin_initials {
    pinyin_initials=$(get_pinyin_initials)
    result=""

    while [[ "$pinyin_initials" =~ ([a-z]*)\|(.*) ]] ||
	      [[ "$pinyin_initials" =~ ([a-z]) ]]; do
	initial=${BASH_REMATCH[1]}
	pinyin_initials=${BASH_REMATCH[2]}

	if [[ "$initial" =~ [^ng] ]]; then
	    result=$result$initial"|"
	fi
    done

    echo $result
}

# error handling is not handled in consumers
# DISCLAIMER: did not consider final only words, such as ai4
# parse pinyin_word by getting initial, and some candidate final
# if candidate final contains n or g, verify with user on syllable
# outputs to stderr 2 for failed parse
function get_pinyin_syllables {
    pinyin_word=$1
    declare -a syllables
    syllable_index=0

    initial_regex=$(get_pinyin_initials)
    strict_initial_regex=$(get_strict_pinyin_initials)

    parse_success=0
    parse_syllable=$pinyin_word
    while [[ "$parse_syllable" =~ ^($initial_regex)(.*)$ ]]; do
	initial=${BASH_REMATCH[1]}
        rest=${BASH_REMATCH[2]}

	if [[ "$rest" =~ ^([^1-4$strict_initial_regex]+[1-4]?)(.*)$ ]]; then
	    final=${BASH_REMATCH[1]}
	    pinyin_syllable=$initial$final

	    if [[ "$final" =~ [ng] ]]; then

		output=""
	        until [[ -n $output ]] && [[ "$pinyin_syllable" =~ ^($output)(.*)$ ]]; do
		    echo "Please provide first syllable (with tone#) of: "$parse_syllable 1>&2
		    read output
		done

		pinyin_syllable=$output
	    fi

	    syllables[$syllable_index]=$pinyin_syllable
	    let syllable_index+=1

	    [[ "$parse_syllable" =~ ^($pinyin_syllable)(.*)$ ]]
	    parse_syllable=${BASH_REMATCH[2]}
	else
	    parse_success=1
	    break
	fi

    done

    if [[ $parse_success -eq 0 ]]; then
	for i in $(seq 0 $(expr $syllable_index - 1)); do
	    echo ${syllables[$i]}
	done
    else
	echo "Was unable to parse syllables of: "$pinyin_word 1>&2
	return 1
    fi
}
