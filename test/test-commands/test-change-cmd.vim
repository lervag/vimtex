set nocompatible
set runtimepath^=../..
filetype plugin on


" csc  /  Change surrounding command
call vimtex#test#keys("csctest\<cr>", '\cmd{foo}', '\test{foo}')


call vimtex#test#finished()
