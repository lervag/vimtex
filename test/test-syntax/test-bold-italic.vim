source common.vim

" let g:vimtex_syntax_conceal = {'styles': 0}
set conceallevel=2

silent edit test-bold-italic.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texStyleBoth', 5, 50))
call assert_true(vimtex#syntax#in('texStyleBoth', 6, 50))
call assert_true(vimtex#syntax#in('texStyleBoth', 8, 50))
call assert_true(vimtex#syntax#in('texCmdStyle', 7, 14))

call vimtex#test#finished()
