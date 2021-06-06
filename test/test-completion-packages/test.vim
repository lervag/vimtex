set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\usepackage{', 'cleve')
call assert_equal(s:candidates[0].word, 'cleveref')

let s:candidates = vimtex#test#completion('\RequirePackage{', 'am')
call assert_true(len(s:candidates) >= 1)

let s:candidates = vimtex#test#completion('\PassOptionsToPackage{option}{', 'am')
call assert_true(len(s:candidates) >= 1)

call vimtex#test#finished()
