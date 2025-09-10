set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

set nomore

setfiletype tex

call vimtex#test#keys('Edid',
      \ '\caption{Testing easy.}',
      \ '\caption{}'
      \)

call vimtex#test#keys('Edad',
      \ '\caption{Testing easy.}',
      \ '\caption'
      \)

call vimtex#test#keys('Edid',
      \ '\caption{Testing {nested}.}',
      \ '\caption{}'
      \)

call vimtex#test#keys('$bdid',
      \ '\caption{Testing {nested} after}',
      \ '\caption{}'
      \)

call vimtex#test#keys('Edid',
      \ '\caption{Testing $math$.}',
      \ '\caption{}'
      \)

call vimtex#test#keys('4jdid', [
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

call vimtex#test#keys('$bdid',
      \ '\caption{Testing $math$ after}',
      \ '\caption{}'
      \)

call vimtex#test#finished()
