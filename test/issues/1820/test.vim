set nocompatible
let &rtp = '~/.vim/bundle/vimtex,' . &rtp
filetype plugin on

let g:tex_flavor = 'latex'

nnoremap q :qall!<cr>
nnoremap w :e test.txt<cr>

silent edit test.tex
silent normal! j

redraw!
echo 'To test: type "w" to edit test.txt'
