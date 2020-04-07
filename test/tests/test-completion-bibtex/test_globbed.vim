set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test_globbed.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\cite{', '')
call vimtex#test#assert_equal(1, len(s:candidates))


quit!
