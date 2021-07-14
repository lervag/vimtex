source common.vim

silent edit test-dockerfile.tex

if empty($INMAKE) | finish | endif

call assert_notequal('# %s', &commentstring)

call vimtex#test#finished()
