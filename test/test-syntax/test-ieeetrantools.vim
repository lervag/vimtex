source common.vim

silent edit test-ieeetrantools.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texMathZoneEnv', 8, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 13, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 24, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 31, 1))

call vimtex#test#finished()
