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
