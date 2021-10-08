set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_persistent = 0

let g:vimtex_toc_custom_matchers = [
      \ { 'title' : 'My Custom Environment',
      \   're' : '\v^\s*\\begin\{quote\}' }
      \]

silent edit main.tex

if empty($INMAKE) | finish | endif

" profile start prof.log
" profile func *

let s:time = vimtex#profile#time()
let s:toc = vimtex#toc#get_entries()
let s:time = vimtex#profile#time(s:time, 'Time elapsed (1st run)')

" profile pause
" quit!

let s:toc = vimtex#toc#get_entries()
let s:time = vimtex#profile#time(s:time, 'Time elapsed (2nd run)')

let s:toc = vimtex#toc#get_entries()
let s:time = vimtex#profile#time(s:time, 'Time elapsed (3rd run)')

quit!
