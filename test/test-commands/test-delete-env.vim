set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

setfiletype tex


" dse  /  Delete surrounding environment
call vimtex#test#keys('dsedse',
      \[
      \ '\begin{test}',
      \ '  \begin{center} a \end{center}',
      \ '\end{test}',
      \], '   a ')


call vimtex#test#finished()
