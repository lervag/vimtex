source common.vim

try
  runtime syntax/tex.vim
catch
  call assert_true(0, 'Bare include of VimTeX syntax should work!')
endtry

call vimtex#test#finished()
