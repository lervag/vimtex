source common.vim

EditConcealed test-dockerfile.tex

if empty($INMAKE) | finish | endif

call assert_notequal('# %s', &commentstring)

call vimtex#test#finished()
