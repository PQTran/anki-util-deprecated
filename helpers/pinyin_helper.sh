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
		*)
		    new_char="a"
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
		*)
		    new_char="o"
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
		*)
		    new_char="e"
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
		*)
		    new_char="i"
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
		*)
		    new_char="u"
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
		*)
		    new_char="ü"
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
	*v*)
	    echo "v"
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
	*)
	    echo ""
	    ;;
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

function _contains_char {
    string=$1

    [[ "$string" =~ .+ ]]
}

function _get_pinyin_initial {
    string=$1
    initial_regex=$(get_pinyin_initials)

    [[ "$string" =~ ^($initial_regex) ]]
    echo ${BASH_REMATCH[1]}
}

function _get_user_response_first_syllable {
    pinyin_word=$1

    first_syllable=""
    until [[ -n $first_syllable ]] &&
	      [[ "$pinyin_word" =~ ^($first_syllable)(.*)$ ]]; do
	prompt="first syllable of [$pinyin_word]: "
	read -u 3 -p "$prompt" first_syllable
	first_syllable=${first_syllable:-$pinyin_word}
    done

    echo $first_syllable
}

function _get_pinyin_final {
    string=$1
    strict_intials=$(get_strict_pinyin_initials)
    final_regex="[^1-4"$strict_intials"]+[1-4]?"

    [[ "$string" =~ ^($final_regex) ]]
    echo ${BASH_REMATCH[1]}
}

function _get_rest_of_string {
    string=$1
    substring=$2

    [[ "$string" =~ ^$substring(.*) ]]
    echo ${BASH_REMATCH[1]}
}

function _syllable_ends_with_either {
    string=$1
    chars=$2

    [[ "$string" =~ [$chars]$ ]]
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

    parse_success=0

    # consider caching results of user input
    while [[ -n $pinyin_word ]] && $(_contains_char $pinyin_word); do
	initial=$(_get_pinyin_initial $pinyin_word)
	if [[ -z $initial ]]; then
	    syllable=$(_get_user_response_first_syllable $pinyin_word)

	    syllables[$syllable_index]=$syllable
	    let syllable_index+=1
	    pinyin_word=$(_get_rest_of_string $pinyin_word $syllable)
	    continue
	fi

        sub_pinyin_word=$(_get_rest_of_string $pinyin_word $initial)
	# takes 1-4 (stops here), or stops at initial (except ng)
	final=$(_get_pinyin_final $sub_pinyin_word)
	if [[ -z $final ]]; then
	    parse_success=1
	    break
	fi

	# if ng found at end, need to verify boundary of syllable
	# skip verification if last syllable
	if [[ $initial$final != $pinyin_word ]] && $(_syllable_ends_with_either $final "ng"); then
	    syllable=$(_get_user_response_first_syllable $pinyin_word)

	    syllables[$syllable_index]=$syllable
	    let syllable_index+=1
	    pinyin_word=$(_get_rest_of_string $pinyin_word $syllable)
	    continue
	fi

	pinyin_syllable=$initial$final

	syllables[$syllable_index]=$pinyin_syllable
	let syllable_index+=1

	pinyin_word=$(_get_rest_of_string $pinyin_word $pinyin_syllable)
    done

    if [[ $parse_success -eq 0 ]]; then
	for i in $(seq 0 $(expr $syllable_index - 1)); do
	    echo ${syllables[$i]}
	done
    else
	echo "Was unable to parse syllables of: "$1 1>&2
	return 1
    fi
}
