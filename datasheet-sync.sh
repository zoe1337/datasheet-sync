#!/bin/sh

cat "datasheets.csv" | while IFS="," read -r url fn desc;
do
    lastmodified=$(curl -sI $url | grep -i Last-Modified)
    if [ "$lastmodified" ] && [ -f "pdf/$fn" ]; then
        urlmodified=$(date -d "$(echo $lastmodified | cut -d ' ' -f2-)")
        filemodified=$(date -r "pdf/$fn")
        if [ "$urlmodified" != "$filemodified" ]; then 
            curl -sR "$url" -o "pdf/$fn"
        fi
    else 
        curl -sR "$url" -o "pdf/$fn"
    fi
done

if [[ $(git status -s | wc -l) -gt "0" ]]; then
    echo "Datasheets changed"

    # get list of new and modified datasheets
    new=$(git status -s | grep '??' | cut -f2 -d' ' | grep -i 'pdf')
    mod=$(git status -s | grep ' M ' | cut -f3 -d' ' | grep -i 'pdf')

    # update text for PDFs
    for fn in $(printf "$mod\n$new"); do
        pdftotext $fn txt/$(basename $fn .pdf).txt
    done

    git status -s
    git add "*.pdf" "*.txt"
    git commit -m "Datasheets updated"
fi
