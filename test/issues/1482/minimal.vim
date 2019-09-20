set nocompatible
let &rtp = '../../../,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

silent edit one/two/include_star.tex
" silent edit one/two/include_file.tex

echo fnamemodify(b:vimtex.tex, ':.') . "\n"

quitall
