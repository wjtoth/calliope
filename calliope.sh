#!/bin/bash

year=$(date +%G)
month=$(date +%m)
day=$(date +%d)
diary_dir="diary"
pdf_dir="pdfs"
todays_entry="$year-$month-$day.tex"
author="Ankur Sinha"
year_to_compile="meh"
entry_to_compile="meh"
style_file="research_diary.sty"
bibliography_file="biblist.bib"
other_files_path="other_files/"
images_files_path="images/"


add_entry ()
{
    echo "Today is $year/$month/$day"
    echo "Your diary is located in: $diary_dir/."

    if [ ! -d "$diary_dir" ]; then
        mkdir "$diary_dir"
    fi

    if [ ! -d "$diary_dir/$year" ]; then
        mkdir "$diary_dir/$year"
        mkdir "$pdf_dir/$year"
        mkdir "$diary_dir/$year/images"
    fi

    if [ -d "$diary_dir/$year" ]; then
        echo "Adding new entry to directory $diary_dir/$year."

        cd "$diary_dir/$year"
        filename="$year-$month-$day.tex"

        if [ -f "$filename" ]; then
            echo "File for today already exists: $diary_dir/$year/$filename."
            echo "Happy writing!"
        else
            if [ ! -f "$style_file" ]; then
                ln -s ../../templates/$style_file .
            fi
            if [ ! -f "$bibliography_file" ]; then
                ln -s ../../$bibliography_file .
            fi

            cp ../../templates/entry.tex "$filename"

            sed -i "s/@year/$year/g" "$filename"
            sed -i "s/@MONTH/$(date +%B)/g" "$filename"
            sed -i "s/@dday/$day/g" "$filename"
            sed -i "s/@day/$(date +%e)/g" "$filename"

            echo "Finished adding $filename to $year."
            cd ../../
        fi
    fi

    if [ -n "$TMUX" ]
    then
        echo "Setting tmux buffer for your convenience."
        tmux set-buffer "$diary_dir/$year/$filename"
    else
        echo "Not using a tmux session. Not setting buffer."
    fi
}

clean ()
{
    rm -fv -- *.aux *.bbl *.blg *.log *.nav *.out *.snm *.toc *.dvi *.vrb *.bcf *.run.xml *.cut *.lo* *.brf*
    latexmk -c
}

compile_today ()
{
    cd "$diary_dir/$year/"
    echo "Compiling $todays_entry."
    latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape" -use-make -bibtex "$todays_entry"
    clean

    if [ ! -d "../../$pdf_dir/$year" ]; then
        mkdir -p "../../$pdf_dir/$year"
    fi
    mv -- *.pdf "../../$pdf_dir/$year/"
    echo "Generated pdf moved to pdfs directory."
    cd ../../
}

compile_latest ()
{
    cd "$diary_dir/$year/"
    latest_entry=$(ls $year*tex | tail -1)
    echo "Compiling $latest_entry."

    latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape" -use-make -bibtex "$latest_entry"
    clean

    if [ ! -d "../../$pdf_dir/$year" ]; then
        mkdir -p "../../$pdf_dir/$year"
    fi
    mv -- *.pdf "../../$pdf_dir/$year/"
    echo "Generated pdf moved to pdfs directory."
    cd ../../

}

compile_all ()
{
    if [ ! -d "$diary_dir/$year_to_compile/" ]; then
      echo "$diary_dir/$year_to_compile/ does not exist. Exiting."
      exit -1
    fi

    cd "$diary_dir/$year_to_compile/"
    echo "Compiling all in $year_to_compile."
    for i in "$year_to_compile"-*.tex ; do
      latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape" -use-make -bibtex "$i"
      clean
    done

    if [ ! -d "../../$pdf_dir/$year_to_compile" ]; then
        mkdir -p ../../$pdf_dir/$year_to_compile
    fi
    mv -- *.pdf "../../$pdf_dir/$year_to_compile/"
    echo "Generated pdf moved to pdfs directory."
    cd ../../
}

compile_specific ()
{
    year=${entry_to_compile:0:4}
    if [ ! -d "$diary_dir/$year/" ]; then
      echo "$diary_dir/$year/ does not exist. Exiting."
      exit -1
    fi

    cd "$diary_dir/$year/"
    echo "Compiling $entry_to_compile"
    latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape" -use-make -bibtex $entry_to_compile
    clean
    if [ ! -d "../../$pdf_dir/$year" ]; then
        mkdir -p ../../$pdf_dir/$year
    fi
    mv -- *.pdf "../../$pdf_dir/$year/"
    echo "Generated pdf moved to pdfs directory."
    cd ../../

}

create_anthology ()
{
    Name="$year_to_compile""-Research-Diary"
    FileName=$Name".tex"
    tmpName=$Name".tmp"

    echo "Research Diary"
    echo "Author: $author"
    echo "Year: $year_to_compile"

    if [ ! -d "$diary_dir/$year_to_compile" ]; then
        echo "ERROR: No directory for $year_to_compile exists"
        exit;
    fi

    cd "$diary_dir"

    touch $FileName
    echo "%" > $FileName
    echo "% Research Diary for $author, $year_to_compile" >> $FileName
    echo "%" >> $FileName
    echo "\documentclass[a4paper,twoside,11pt]{report}" >> $FileName
    echo "\newcommand{\workingDate}{\textsc{$year_to_compile}}" >> $FileName
    echo "\newcommand{\userName}{$author}" >> $FileName
    echo "\usepackage{research_diary}" >> $FileName
    echo " " >> $FileName
    echo "\title{Research Diary - $year_to_compile}" >> $FileName
    echo "\author{$author}" >> $FileName
    echo " " >> $FileName

    echo "\rhead{\textsc{$year_to_compile}}" >> $FileName
    echo "\chead{\textsc{Research Diary}}" >> $FileName
    echo "\lhead{\textsc{\userName}}" >> $FileName
    echo "\rfoot{\textsc{\thepage}}" >> $FileName
    echo "\cfoot{\textit{Last modified: \today}}" >> $FileName
    echo "\graphicspath{{./$year_to_compile/$images_files_path}}" >> $FileName
    echo "\lstset{{inputpath=./$year_to_compile/$other_files_path}}" >> $FileName

    echo " " >> $FileName
    echo " " >> $FileName
    echo "\begin{document}" >> $FileName
    echo "\begin{center} \begin{LARGE}" >> $FileName
    echo "\textbf{Research Diary} \\\\[3mm]" >> $FileName
    echo "\textbf{$year_to_compile} \\\\[2cm]" >> $FileName
    echo "\end{LARGE} \begin{large}" >> $FileName
    echo "$author \end{large} \\\\" >> $FileName
    echo "\textsc{Compiled \today}" >> $FileName
    echo "\end{center}" >> $FileName
    echo "\thispagestyle{empty}" >> $FileName
    echo "\newpage" >> $FileName
    echo "\tableofcontents" >> $FileName
    echo "\thispagestyle{empty}" >> $FileName
    # echo "\clearpage" >> $FileName

    for i in "$year_to_compile"/"$year_to_compile"-*.tex ; do
        echo -e "\n%%% --- $i --- %%%\n" >> $tmpName
        echo "\rhead{`grep workingDate $i | cut -d { -f 4 | cut -d } -f 1`}" >> $tmpName
        sed -n '/\\begin{document}/,/\\end{document}/p' $i >> $tmpName
        echo -e "\n" >> $tmpName
        echo "\newpage" >> $tmpName
    done

    # uncomment the chapter line
    sed -i 's/%\\chapter/\\chapter/' $tmpName
    sed -i 's/\\begin{document}//g' $tmpName
    sed -i 's/\\printindex//g' $tmpName
    sed -i 's/\\bibliography.*$//g' $tmpName
    sed -i 's/\\end{document}//g' $tmpName
    sed -i 's|\\includegraphics\(.*\)'"$images_files_path"'\(.*\)|\\includegraphics\1\2|g' $tmpName
    sed -i 's|\\lstinputlisting\(.*\)'"$other_files_path"'\(.*\)|\\lstinputlisting\1\2|g' $tmpName
    sed -i 's|\\inputminted\(.*\)\('"$other_files_path"'\)\(.*\)|\\inputminted\1'"./$year_to_compile/"'\2\3|g' $tmpName
    # with options: options can contain a {, so need to handle them first
    sed -i 's/\\includepdf\(\[.*\]\){\(.*\)/\\includepdf\1{'"$year_to_compile"'\/\2/g' $tmpName
    # without options
    sed -i 's/\\includepdf{\(.*\)/\\includepdf{'"$year_to_compile"'\/\1/g' $tmpName
    sed -i 's/\\newcommand/\\renewcommand/g' $tmpName

    cat $tmpName >> $FileName
    echo "\bibliography{biblist}" >> $FileName
    echo "\printindex" >> $FileName
    echo "\end{document}" >> $FileName

    if [ ! -f "$style_file" ]; then
        ln -sf ../templates/$style_file .
    fi
    if [ ! -f "$bibliography_file" ]; then
        ln -sf ../$bibliography_file .
    fi

    latexmk -pdf -recorder -pdflatex="pdflatex -interaction=nonstopmode --shell-escape" -use-make -bibtex $FileName
    mv -- *.pdf "../$pdf_dir/"

    clean
    rm $tmpName

    echo "$year_to_compile master document created in $pdf_dir."
    cd ../
}

usage ()
{
    cat << EOF
    usage: $0 options

    Master script file that provides functions to maintain a journal using LaTeX.

    OPTIONS:
    -h  Show this message and quit

    -t  Add new entry for today

    -l  Compile latest entry

    -c  Compile today's entry

    -a  <year>
        Year to generate anthology of

    -p  <year>
        Compile all entries in this year

    -s  <entry> (yyyy-mm-dd)
        Compile specific entry

EOF

}

if [ "$#" -eq 0 ]; then
    usage
    exit 0
fi

while getopts "ltca:hp:s:" OPTION
do
    case $OPTION in
        t)
            add_entry
            exit 0
            ;;
        l)
            compile_latest
            exit 0
            ;;
        c)
            compile_today
            exit 0
            ;;
        a)
            year_to_compile=$OPTARG
            create_anthology
            exit 0
            ;;
        h)
            usage
            exit 0
            ;;
        p)
            year_to_compile=$OPTARG
            compile_all
            exit 0
            ;;
        s)
            entry_to_compile=$OPTARG
            compile_specific
            exit 0
            ;;
        ?)
            usage
            exit 0
            ;;
    esac
done
