set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

if !empty($BACKEND)
  let g:vimtex_parser_bib_backend = $BACKEND
endif

silent edit bibspeed.tex

if empty($INMAKE) | finish | endif

normal! 10G

" execute 'profile start' 'bibspeed-' . g:vimtex_parser_bib_backend . '.log'
" profile func *

silent let s:time = str2float(system('date +"%s.%N"'))
silent call vimtex#test#completion('\cite{', '')
echo 'Backend:' toupper(g:vimtex_parser_bib_backend)
echo 'Time elapsed (1st run):' str2float(system('date +"%s.%N"')) - s:time "\n"

" profile pause

let s:time = str2float(system('date +"%s.%N"'))
call vimtex#test#completion('\cite{', '')
echo 'Time elapsed (2nd run):' str2float(system('date +"%s.%N"')) - s:time "\n"

let s:time = str2float(system('date +"%s.%N"'))
let s:candidates = vimtex#test#completion('\cite{', '')
echo 'Time elapsed (3rd run):' str2float(system('date +"%s.%N"')) - s:time "\n"
echo 'Number of candidates:' len(s:candidates)
echo "\n"

quit!
