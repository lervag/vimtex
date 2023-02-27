source common.vim

EditConcealed test-mathtools.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texMathZoneEnv', 7, 1))

call vimtex#test#finished()
