set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

set nomore

setfiletype tex

call vimtex#test#keys('02f+d2ac',
      \ 'a + \bar{\mathit{c + d}} =',
      \ 'a +  =')

call vimtex#test#keys('fdd2ad',
      \ 'a + \left(b + \left[c + d \right] + e\right) + f',
      \ 'a +  + f')

call vimtex#test#keys('f\dac',
      \ 'a + \test[opt1][opt2]{arg} + f',
      \ 'a +  + f')

call vimtex#test#keys('f\dac',
      \ 'a + \; f',
      \ 'a +  f')

call vimtex#test#keys('di$',
      \ 'Hello world! $(x)$',
      \ 'Hello world! $$')

call vimtex#test#keys('da$',
      \ 'Hello world! $(x)$',
      \ 'Hello world! ')

call vimtex#test#keys('jjda$',
      \ [
      \   '\documentclass{minimal}',
      \   '\begin{document}',
      \   'Hello world!',
      \   '\end{document}',
      \ ],
      \ [
      \   '\documentclass{minimal}',
      \   '\begin{document}',
      \   'Hello world!',
      \   '\end{document}',
      \ ],
      \)

call vimtex#test#keys('jjfxda$',
      \ [
      \   '\documentclass{minimal}',
      \   '\begin{document}',
      \   '\begin{equation} x \end{equation}',
      \   '$y$',
      \   '\end{document}',
      \ ],
      \ [
      \   '\documentclass{minimal}',
      \   '\begin{document}',
      \   '',
      \   '$y$',
      \   '\end{document}',
      \ ],
      \)


call vimtex#test#finished()
