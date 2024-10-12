set nocompatible
set runtimepath^=../..
filetype plugin on


" tsd  /  Toggle surrounding delimiter
call vimtex#test#keys('3jtsd', [
      \ '$\bigl(\begin{smallmatrix}',
      \ '  \Q^* &   \\',
      \ '       & 1 \\',
      \ '\end{smallmatrix}\bigr)$',
      \], [
      \ '$(\begin{smallmatrix}',
      \ '  \Q^* &   \\',
      \ '       & 1 \\',
      \ '\end{smallmatrix})$',
      \])

" Cf. #1620
call vimtex#test#keys('f+tsd', '\( a^2 + b^2 = c^2 \)', '\( a^2 + b^2 = c^2 \)')

" Cf. #3024
call vimtex#test#keys('4jtsd', [
      \ 'An interval like',
      \ '\begin{equation}',
      \ '  I = (0, 1]',
      \ '\end{equation}',
      \ 'is called half-open, just like the interval',
      \ '\[',
      \ '  J = [0, 1)',
      \ '\]',
      \], [
      \ 'An interval like',
      \ '\begin{equation}',
      \ '  I = (0, 1]',
      \ '\end{equation}',
      \ 'is called half-open, just like the interval',
      \ '\[',
      \ '  J = [0, 1)',
      \ '\]',
      \])

call vimtex#test#finished()
