#!/bin/bash

if [[ -z "$HELPERS_DIR" ]]; then
    HELPERS_DIR="../helpers"
fi

PINYIN_ACCENTS_MAP="$HELPERS_DIR/pinyin-vowels.txt"

function _get_all_accent_characters {
    exec 9<&0

    local result=""
    while IFS=',' read -r -u 9 pinyin char; do
        result="$result$char"
    done 9< "$PINYIN_ACCENTS_MAP"
    exec 9<&-

    echo "$result"
}

function _get_accent_character {
    local vowel=$1
    local tone=$2

    exec 9<&0
    local result=""
    while IFS=',' read -r -u 9 key accent_char; do
        if [[ "$vowel$tone" == "$key" ]]; then
            result="$accent_char"
        fi
    done 9< "$PINYIN_ACCENTS_MAP"
    exec 9<&-

    echo "$result"
}

function _get_pinyin_character {
    local accent=$1

    exec 9<&0
    local result=""
    while IFS=',' read -r -u 9 pinyin key; do
        if [[ "$accent" == "$key" ]]; then
            result="$pinyin"
        fi
    done 9< "$HELPERS_DIR/pinyin-vowels.txt"
    exec 9<&-

    echo "$result"
}

function accent_vowel {
    local word=$1
    local vowel=$2
    local tone=$3

    local accent_char
    accent_char="$(_get_accent_character "$vowel" "$tone")"

    local result
    result="$(replace_char "$word" "$vowel" "$accent_char")"

    echo "$result"
}

# does not properly place tone at end of syllable
function get_pinyin_from_accent_word {
    local accent_word=$1

    local accent_regex
    accent_regex="$(_get_all_accent_characters)"

    local result=""
    local head_str accent_char tail_str
    while true; do
        [[ "$accent_word" =~ (^[^$accent_regex]+)([$accent_regex])(.*) ]]

        head_str="${BASH_REMATCH[1]}"
        accent_char="${BASH_REMATCH[2]}"
        tail_str="${BASH_REMATCH[3]}"

        pinyin="$(_get_pinyin_character "$accent_char")"
        result="$result$head_str$pinyin"

        if [[ "$tail_str" =~ [$accent_regex] ]]; then
            accent_word="$tail_str"
        else
            result="$result$tail_str"
            break
        fi

    done

    echo "$result"
}

# aoeiuv
# iu or ui makes the second vowel accented
function get_dominant_vowel {
    local string=$1

    local dominant_vowel
    case "$string" in
	*a*)
	    dominant_vowel="a"
	    ;;
	*o*)
	    dominant_vowel="o"
	    ;;
	*e*)
	    dominant_vowel="e"
	    ;;
	*ui*)
	    dominant_vowel="i"
	    ;;
	*iu*)
	    dominant_vowel="u"
	    ;;
	*i*)
	    dominant_vowel="i"
	    ;;
	*u*)
	    dominant_vowel="u"
	    ;;
	*v*)
	    dominant_vowel="v"
	    ;;
	*)
            echo "unable to parse dominant vowel" 1>&2
            exit 1
    esac

    echo "$dominant_vowel"
}

function get_tone {
    local pinyin_syllable=$1

    local tone
    case "$pinyin_syllable" in
	*1)
	    tone="1"
	    ;;
	*2)
	    tone="2"
	    ;;
	*3)
	    tone="3"
	    ;;
	*4)
	    tone="4"
	    ;;
	*)
	    tone=""
	    ;;
    esac

    echo "$tone"
}

function update_pinyin {
    local syllable=$1
    local vowel=$2
    local tone=$3

    if [[ -z "$vowel" ]] ||
	   [[ -z "$tone" ]]; then
        exit 1
    fi

    syllable="${syllable::-1}"

    local result
    result="$(accent_vowel "$syllable" "$dominant_vowel" "$tone")"

    echo "$result"
}

function get_pinyin_initials {
    local pinyin_initials
    pinyin_initials="$(cat "$HELPERS_DIR/pinyin-initials.txt")"

    echo "$pinyin_initials"
}

function get_strict_pinyin_initials {
    local pinyin_initials result
    pinyin_initials="$(get_pinyin_initials)"
    result=""

    local initial pinyin_initials
    while [[ "$pinyin_initials" =~ ([a-z]*)\|(.*) ]] ||
	      [[ "$pinyin_initials" =~ ([a-z]) ]]; do
	initial="${BASH_REMATCH[1]}"
	pinyin_initials="${BASH_REMATCH[2]}"

	if [[ "$initial" =~ [^ng] ]]; then
            if [[ -z "$result" ]]; then
                result="$initial"
            else
	        result="$result|$initial"
            fi
	fi
    done

    echo "$result"
}

function _contains_char {
    local string=$1

    [[ "$string" =~ .+ ]]
}

function _get_pinyin_initial {
    local string=$1

    local initial_regex
    initial_regex="$(get_pinyin_initials)"

    [[ "$string" =~ ^($initial_regex) ]]
    echo "${BASH_REMATCH[1]}"
}

function _get_user_response_first_syllable {
    local word=$1
    local first_syllable=""

    exec 3<&0
    local prompt="first syllable of [$word]: "
    while true; do
	read -r -u 3 -p "$prompt" first_syllable

        if [[ -z "$first_syllable" ]]; then
            echo "$word"
            break
        elif [[ "$word" =~ ^($first_syllable).*$ ]]; then
            echo "$first_syllable"
            break
        else
            echo "Incorrect input, try again!" 1>&2
            echo "" 1>&2
        fi
    done
    exec 3>&-
}


# assumption input does not start with initial
# must change to operate on normal string

# check for ng[1-4] final
# if ambiguous final, return empty string / fail
function _get_pinyin_final {
    local substring=$1

    local strict_initials
    strict_initials="$(get_strict_pinyin_initials)"
    # (strict finals + n/g) + tone?
    local final_regex="[^1-4$strict_initials]+[1-4]?"

    [[ "$substring" =~ ^($final_regex) ]]
    local final="${BASH_REMATCH[1]}"

    # must check the condition where intials exist
    # before and after n|g
    [[ "$final" =~ [$strict_initials]+[ng][$strict_initials]+ ]]
    response=$?

    if [[ "$response" -eq 0 ]]; then
        echo ""
    else
        echo "$final"
    fi
}

function _get_rest_of_string {
    local string=$1
    local beginning=$2

    [[ "$string" =~ ^$beginning(.*) ]]
    local rest="${BASH_REMATCH[1]}"

    echo "$rest"
}

function _syllable_ends_with_either {
    local string=$1
    local chars=$2

    [[ "$string" =~ [$chars]$ ]]
}

function get_cache {
    local cache_key=$1

    exec 6<&0
    while IFS=',' read -r -u 6 key value; do
        if [[ "$cache_key" == "$key" ]]; then
            echo "$value"
            break
        fi
    done 6< "$OUTPUT_SYLLABLE_CACHE"
    exec 6>&-
}

function set_cache {
    local key=$1
    local value=$2

    echo "$key,$value" >> "$OUTPUT_SYLLABLE_CACHE"
}

# requires user confirmation:
# syllables starting with finals, ai4
# n or g in middle of word without tone (uncommon)

# can be implemented storing results in an array
function get_pinyin_syllables {
    local word=$1
    local syllables=""

    while true; do
        local parse_success=0

        local initial sub_word final syllable
        while [[ -n "$word" ]]; do
	    initial="$(_get_pinyin_initial "$word")"
	    if [[ -z "$initial" ]]; then
                parse_success=1
                break
            fi

            sub_word="$(_get_rest_of_string "$word" "$initial")"
            # stops after tone number, or before an initial (except n, ng)
	    final="$(_get_pinyin_final "$sub_word")"
	    if [[ -z "$final" ]]; then
	        parse_success=1
	        break
	    fi

            # user intercepts if ambiguous syllable
	    syllable="$initial$final"
	    if [[ "$syllable" != "$word" ]] &&
                   _syllable_ends_with_either "$final" "ng"; then
                parse_success=1
                break
	    fi

            # update syllables store
            if [[ -z "$syllables" ]]; then
                syllables="$syllable"
            else
                syllables="$syllables\n$syllable"
            fi

	    word="$(_get_rest_of_string "$word" "$syllable")"
        done

        if [[ "$parse_success" -eq 0 ]]; then
            echo -e "$syllables"
            break
        else
            syllable="$(get_cache "$word")"

            if [[ -z "$syllable" ]]; then
	        syllable="$(_get_user_response_first_syllable "$word")"
                set_cache "$word" "$syllable"
            fi

	    word="$(_get_rest_of_string "$word" "$syllable")"

            if [[ -z "$syllables" ]]; then
                syllables="$syllable"
            else
                syllables="$syllables\n$syllable"
            fi
        fi
    done
}
