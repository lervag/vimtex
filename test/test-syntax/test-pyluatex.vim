source common.vim

EditConcealed test-pyluatex.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('pythonString', 7, 13))
call assert_true(vimtex#syntax#in('pythonString', 11, 13))
call assert_true(vimtex#syntax#in('pythonString', 15, 13))

call vimtex#test#finished()
