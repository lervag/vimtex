set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

setfiletype tex


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


call vimtex#test#finished()
