source common.vim

EditConcealed test-mleftright.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texMathDelim', 7, 19))

call vimtex#test#finished()
