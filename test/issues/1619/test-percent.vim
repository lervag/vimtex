set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

silent edit test-percent.tex
silent normal! jdd50000p

if empty($INMAKE) | finish | endif

" Test for #1619
g/\\textbf/normal 0ww%iEND

let s:lines = getline(1, '$')
echo s:lines[0] "\n"
echo s:lines[1] "\n"
echo s:lines[2] "\n"
echo s:lines[-3] "\n"
echo s:lines[-2] "\n"
echo s:lines[-1] "\n"
call vimtex#test#assert(s:lines[1] =~# '^END')
call vimtex#test#assert(s:lines[-1] =~# '^END')

quit!
