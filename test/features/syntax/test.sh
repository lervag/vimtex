#!/bin/sh

if [ ! -f "syntax/asy.vim" ]; then
  mkdir -p syntax
  wget https://raw.githubusercontent.com/vectorgraphics/asymptote/master/base/asy.vim syntax/asy.vim
fi

vim -u minivimrc
