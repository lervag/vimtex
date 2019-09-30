set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

if !empty($BACKEND)
  let g:vimtex_parser_bib_backend = $BACKEND
endif

if empty($MAKE) | finish | endif

silent edit main.tex

" let g:vimtex_complete_bib_simple = 1

" normal! 10G

" " execute 'profile start' 'bibspeed-' . g:vimtex_parser_bib_backend . '.log'
" " profile func *

" echo 'Backend:' toupper(g:vimtex_parser_bib_backend)
" let s:time = str2float(system('date +"%s.%N"'))
" execute "normal A\<c-x>\<c-o>"
" echo 'Time elapsed (1st run):' str2float(system('date +"%s.%N"')) - s:time "\n"
" silent! normal! u

" " profile pause

" let s:time = str2float(system('date +"%s.%N"'))
" execute "normal A\<c-x>\<c-o>"
" echo 'Time elapsed (2nd run):' str2float(system('date +"%s.%N"')) - s:time "\n"

" let s:time = str2float(system('date +"%s.%N"'))
" let s:candidates = vimtex#complete#omnifunc(0, '')
" echo 'Time elapsed (3rd run):' str2float(system('date +"%s.%N"')) - s:time "\n"
" echo 'Number of candidates:' len(s:candidates)
" echo "\n"

" quit!
