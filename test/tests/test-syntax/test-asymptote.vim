source common.vim

let &rtp = '.,' . &rtp

silent edit test-asymptote.tex

if empty($INMAKE) | finish | endif


quit!
