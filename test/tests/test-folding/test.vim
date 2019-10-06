set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set fillchars=fold:\ 
set number
set foldcolumn=4

nnoremap q :qall!<cr>

let g:vimtex_fold_enabled = 1
let g:vimtex_fold_types = {'comments' : {'enabled': 1}}

silent edit main.tex

if empty($MAKE) | finish | endif


call vimtex#test#assert_equal(foldlevel(1), 1)
call vimtex#test#assert_equal(foldlevel(2), 2)
call vimtex#test#assert_equal(foldlevel(34), 2)
call vimtex#test#assert_equal(foldlevel(48), 2)
call vimtex#test#assert_equal(foldlevel(128), 3)
call vimtex#test#assert_equal(foldlevel(144), 2)

call vimtex#test#assert_equal(foldtextresult(1), '      Preamble')
call vimtex#test#assert_equal(foldtextresult(48), '\usepackage[...]{biblatex}')
call vimtex#test#assert_equal(foldtextresult(63),
      \ '\newcommand*{\StoreCiteField}[3]{%')
call vimtex#test#assert_equal(foldtextresult(105),
      \ '\pgfplotstableread[col sep=semicolon,trim cells]{...}{\datatable}')
call vimtex#test#assert_equal(matchstr(foldtextresult(146), '(.*)$'),
      \ '(sec:test1-longer label)')
call vimtex#test#assert_equal(foldtextresult(153), '% {{{ Testing markers')

quit!
