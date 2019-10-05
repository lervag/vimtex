set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

let s:candidates = vimtex#test#completion('\usepackage{', 'cleve')
call vimtex#test#assert_equal(s:candidates[0].word, 'cleveref')

let s:candidates = vimtex#test#completion('\RequirePackage{', 'ams')
call vimtex#test#assert_equal(len(s:candidates), 18)

let s:candidates = vimtex#test#completion('\PassOptionsToPackage{option}{', 'bb')
call vimtex#test#assert_equal(len(s:candidates), 4)

quit!
