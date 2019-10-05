set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

" Candidates from \newenvironment
let s:candidates = vimtex#test#completion('\begin{', 'test')
call vimtex#test#assert_equal(s:candidates[0].word, 'testnewenvironment')

" Candidates from package (align from amsmath)
let s:candidates = vimtex#test#completion('\begin{', 'ali')
call vimtex#test#assert_equal(s:candidates[0].word, 'align')

quit!
