set nocompatible
let &rtp = '~/.vim/bundle/vimtex,' . &rtp
let &rtp .= ',~/.vim/bundle/vimtex/after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

silent edit input.tex

normal 15ggds$
normal 11ggds$
normal 8ggf$ds$
normal 5ggds$

write! output.tex
quitall!
