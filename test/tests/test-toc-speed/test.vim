set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
" let g:vimtex_cache_persistent = 0

let g:vimtex_toc_custom_matchers = [
      \ { 'title' : 'My Custom Environment',
      \   're' : '\v^\s*\\begin\{quote\}' }
      \]

silent edit main.tex

if empty($INMAKE) | finish | endif

" profile start prof.log
" profile func *

silent let s:time = str2float(system('date +"%s.%N"'))
let s:toc = vimtex#toc#get_entries()
echo 'Time elapsed (1st run):' str2float(system('date +"%s.%N"')) - s:time "\n"

" profile pause
" quit!

let s:time = str2float(system('date +"%s.%N"'))
let s:toc = vimtex#toc#get_entries()
echo 'Time elapsed (2nd run):' str2float(system('date +"%s.%N"')) - s:time "\n"

let s:time = str2float(system('date +"%s.%N"'))
let s:toc = vimtex#toc#get_entries()
echo 'Time elapsed (3rd run):' str2float(system('date +"%s.%N"')) - s:time "\n"

quit!
