source common.vim

EditConcealed test-breqn.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texMathZoneEnv', 9, 1))

call vimtex#test#finished()

