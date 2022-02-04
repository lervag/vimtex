set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

setfiletype tex


" ds$  /  Delete surrounding math ($...$ and \[...\])
call vimtex#test#keys('f$ds$',
      \ 'for $ 2+2 = 4 = 3 $ etter',
      \ 'for 2+2 = 4 = 3 etter')
call vimtex#test#keys('jds$',
      \[
      \ 'asd $',
      \ '2+2 = 4',
      \ '$ asd',
      \],
      \[
      \ 'asd',
      \ '2+2 = 4',
      \ 'asd',
      \])
call vimtex#test#keys('ds$',
      \[
      \ '\[',
      \ '2+2 = 4',
      \ '\]',
      \], '2+2 = 4')


call vimtex#test#finished()
