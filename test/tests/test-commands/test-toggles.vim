set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on
syntax on

set nomore
set autoindent

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

quit!
