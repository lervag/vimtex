set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test1.tex

if empty($INMAKE) | finish | endif

" Candidates from \newenvironment
let s:candidates = vimtex#test#completion('\begin{', 'test')
call vimtex#test#assert_equal(s:candidates[0].word, 'testnewenvironment')

" Candidates from package (align from amsmath)
let s:candidates = vimtex#test#completion('\begin{', 'ali')
call vimtex#test#assert_equal(s:candidates[0].word, 'align')

quit!
