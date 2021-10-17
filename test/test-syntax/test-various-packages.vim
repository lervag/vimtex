source common.vim

silent edit test-various-packages.tex

if empty($INMAKE) | finish | endif

call assert_equal(11, len(filter(b:vimtex_syntax, 'v:val.__loaded')))

call vimtex#test#finished()
