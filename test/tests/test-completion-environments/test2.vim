set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test2.tex

if empty($INMAKE) | finish | endif

" Candidates from \newenvironment from custom classes
let s:candidates = vimtex#test#completion('\begin{', 'test2')
call vimtex#test#assert_equal(len(s:candidates), 2)
call vimtex#test#assert_equal(s:candidates[0].word, 'test2Simple')
call vimtex#test#assert_equal(s:candidates[1].word, 'test2Boxed')

quit!
