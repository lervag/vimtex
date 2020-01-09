set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:input = split(system('shuf -n 100000 -i 1-1000000'))

profile start prof.log
profile func *

let s:output = vimtex#util#uniq_unsorted(s:input)

profile pause
quit!
