source common.vim

silent edit test-ifnextchar.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texConditionalINCChar', 3, 28))
call assert_equal([], vimtex#syntax#stack(8, 1))

call vimtex#test#finished()
