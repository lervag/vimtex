source common.vim

silent edit test-cleveref.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert_equal(3, len(filter(b:vimtex_syntax, 'v:val.__loaded')))

quit!
