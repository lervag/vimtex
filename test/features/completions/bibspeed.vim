set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit bibspeed.tex

if empty($MAKE) | finish | endif

normal! 10G

profile start bibspeed.log
profile func *

let s:time = str2float(system('date +"%s.%N"'))
execute "normal A\<c-x>\<c-o>"
echo 'Time elapsed (1st run):' str2float(system('date +"%s.%N"')) - s:time "\n"
silent! normal! u

profile pause

let s:time = str2float(system('date +"%s.%N"'))
execute "normal A\<c-x>\<c-o>"
echo 'Time elapsed (2nd run):' str2float(system('date +"%s.%N"')) - s:time "\n"

let s:time = str2float(system('date +"%s.%N"'))
let s:candidates = vimtex#complete#omnifunc(0, '')
echo 'Time elapsed (3rd run):' str2float(system('date +"%s.%N"')) - s:time "\n"
echo 'Number of candidates:' len(s:candidates) "\n"

quit!
