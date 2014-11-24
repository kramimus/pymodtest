#!/bin/bash

declare -A totest

pyfiles=$(git ls-files --others -m -c | grep ".py$")
for f in $pyfiles; do
    if [[ "$f" =~ "/test_" ]]; then
        totest[${f/\.py/}]=1
    elif [[ "$f" =~ "__init__" ]]; then
        echo "skipping $f"
    else
        withtestpath=${f/\//\/tests\/}
        withtestprefix=$(echo $withtestpath | sed 's/\([a-zA-Z_]*\)\.py/test_\1/')
        totest[$withtestprefix]=1
    fi
done
all=${!totest[@]}

autopep8 -i --max-line-length=80 $pyfiles
git-lint
python -m unittest ${all//\//\.}




