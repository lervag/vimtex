set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test3.tex

if empty($INMAKE) | finish | endif

" Candidates from \newenvironment from custom classes
let s:candidates = vimtex#test#completion('\begin{', 'test3')
call vimtex#test#assert_equal(len(s:candidates), 2)
call vimtex#test#assert_equal(s:candidates[0].word, 'test3Simple')
call vimtex#test#assert_equal(s:candidates[1].word, 'test3Boxed')

quit!
