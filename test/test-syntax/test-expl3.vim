source common.vim

EditConcealed test-expl3.tex

if empty($INMAKE) | finish | endif

call assert_true(!vimtex#syntax#in('texGroupError', 29, 1))

call assert_false(vimtex#syntax#in('texSpecialChar', 72, 6))

call vimtex#test#finished()
