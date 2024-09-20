source common.vim

Edit test-beamer.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texVerbZone', 6, 1))

call vimtex#test#finished()
