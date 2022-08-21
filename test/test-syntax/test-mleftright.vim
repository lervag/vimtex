source common.vim

highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue

silent edit test-mleftright.tex

vsplit
silent wincmd w
silent windo set scrollbind
set conceallevel=2

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texMathDelim', 7, 19))

call vimtex#test#finished()
