#!/bin/bash

show_help() {
    cat <<EOF
Usage: ${0##*/} [-hcs]

    -h Show this help

    -s Check staged files

    -c Check files in previous commit
EOF
}

filter_existing() {
    pyfiles=$@
    existingfiles=""
    for f in $pyfiles; do
        if [ -e $f ]; then
            existingfiles=$(echo "$existingfiles $f")
        fi
    done
    echo "$existingfiles"
}

get_test_packages() {
    for f in $pyfiles; do
        if [[ "$f" =~ "/test_" ]]; then
            totest[${f/\.py/}]=1
        elif [[ "$f" =~ "__init__" ]]; then
            echo "skipping $f"
        else
            withtestpath=${f/\//\/tests\/}
            withtestprefix=$(echo $withtestpath | sed 's/\([a-zA-Z_]*\)\.py/test_\1/')
            if [ -e "${withtestprefix}.py" ]; then
                totest[$withtestprefix]=1
            fi
        fi
    done
    echo "${!totest[@]}"
}


while getopts ":sc" opt; do
    case $opt in
        c)
            files=$(git diff HEAD^ --name-only)
            ;;
        s)
            files=$(git diff --cached --name-only)
            ;;
    esac
done

if [ -z "$files" ]; then
    show_help
    exit -1
fi

pyfiles=$(echo "$files" | grep ".py$" | grep -v "/migrations/")
declare -A totest

echo $pyfiles
pyfiles=$(filter_existing $pyfiles)
all=$(get_test_packages $pyfiles)

autopep8 -i --max-line-length=80 $pyfiles
prospector | grep -E -A2 $(echo "${pyfiles// /|}" | sed 's/^|//' | sed 's/|$//')

echo ${all//\//\.}
~/rescale/rescale-platform-web/manage.py test ${all//\//\.}
