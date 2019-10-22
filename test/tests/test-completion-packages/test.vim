set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\usepackage{', 'cleve')
call vimtex#test#assert_equal(s:candidates[0].word, 'cleveref')

let s:candidates = vimtex#test#completion('\RequirePackage{', 'am')
call vimtex#test#assert_equal(len(s:candidates) >= 1, v:true)

let s:candidates = vimtex#test#completion('\PassOptionsToPackage{option}{', 'am')
call vimtex#test#assert_equal(len(s:candidates) >= 1, v:true)

quit!
