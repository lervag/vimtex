set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

silent edit test-percent.tex

" vint: -ProhibitCommandRelyOnUser

if empty($INMAKE) | finish | endif

" Test for #1619
normal! jyy50000p
g/\\textbf/normal 0ww%iEND

let s:lines = getline(1, '$')
echo s:lines[:5] "\n"
echo s:lines[-5:] "\n"
call vimtex#test#assert(s:lines[-4] =~# '^END')
call vimtex#test#assert(s:lines[-1] =~# '^END')

quit!
