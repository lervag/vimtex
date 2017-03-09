#!/usr/bin/bash

./generate_files.py
time vim +q -u minivimrc example_00001.tex
rm example_*.tex
