set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

set spell

silent edit deep_input.tex
