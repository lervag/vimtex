set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test3.tex

if empty($INMAKE) | finish | endif

" call vimtex#profile#start()

" " Test commands from custom classes for speed
let s:candidates = vimtex#test#completion('\', '')
call vimtex#test#assert(len(s:candidates) > 0)

" call vimtex#profile#stop()
" call vimtex#profile#filter([
"       \ 'FUNCTIONS SORTED ON SELF',
"       \ 'FUNCTIONS SORTED ON TOTAL',
"       \ 'FUNCTION  vimtex#fold#level',
"       \])
" call vimtex#profile#print()
" call vimtex#profile#open()

quit!
