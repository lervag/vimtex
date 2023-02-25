set nocompatible
set runtimepath^=../..
filetype plugin on


" F7   /  Insert command (insert mode, normal mode and visual mode)
call vimtex#test#keys("lla\<f7>}", 'foobar', '\foo{bar}')
call vimtex#test#keys("llla\<f7>bar}", 'foo*', '\foo*{bar}')
call vimtex#test#keys("llla\<f7>}", 'foo*bar', '\foo*{bar}')
call vimtex#test#keys("fbve\<f7>emph\<cr>", 'foobar', 'foo\emph{bar}')
call vimtex#test#keys("\<f7>emph\<cr>", 'foo', '\emph{foo}')


call vimtex#test#finished()
