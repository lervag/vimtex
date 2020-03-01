set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test_jobname.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\bibentry{', '')
call vimtex#test#assert_equal(len(s:candidates), 1)


quit!
