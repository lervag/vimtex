source common.vim

silent edit test-array.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texTabularCol', 10, 17))
call assert_true(vimtex#syntax#in('texTabularCol', 16, 18))
call assert_true(vimtex#syntax#in('texTabularMathdelim', 10, 24))
call assert_true(vimtex#syntax#in('texTabularCol', 32, 18))

call vimtex#test#finished()
