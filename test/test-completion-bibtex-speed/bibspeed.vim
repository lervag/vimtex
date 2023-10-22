set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0
if !empty($BACKEND)
  let g:vimtex_parser_bib_backend = $BACKEND
endif

silent edit bibspeed.tex

if empty($INMAKE) | finish | endif

if g:vimtex_parser_bib_backend ==# 'lua' && !has('nvim')
  call vimtex#test#finished()
endif

normal! 10G

" execute 'profile start' 'bibspeed-' . g:vimtex_parser_bib_backend . '.log'
" profile func *

let s:time = vimtex#profile#time()
silent call vimtex#test#completion('\cite{', '')
echo 'Backend:' toupper(g:vimtex_parser_bib_backend)
let s:time = vimtex#profile#time(s:time, 'Time elapsed (1st run)')

" profile pause

call vimtex#test#completion('\cite{', '')
let s:time = vimtex#profile#time(s:time, 'Time elapsed (2nd run)')

let s:candidates = vimtex#test#completion('\cite{', '')
let s:time = vimtex#profile#time(s:time, 'Time elapsed (3rd run)')
echo 'Number of candidates:' len(s:candidates)
echo "\n"

quit!
