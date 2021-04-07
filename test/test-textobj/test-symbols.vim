set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

set nomore

setfiletype tex

call vimtex#test#keys('dax',
      \ ['$Cx_0^{1/2} y$'],
      \ ['$x_0^{1/2} y$'])
call vimtex#test#keys('ldax',
      \ ['$Cx_0^{1/2} y$'],
      \ ['$x_0^{1/2} y$'])
call vimtex#test#keys('lldax',
      \ ['$Cx_0^{1/2} y$'],
      \ ['$C y$'])

call vimtex#test#keys('dax',
      \ ['$e^{a x^3}$'],
      \ ['$$'])
call vimtex#test#keys('fadax',
      \ ['$e^{a x^3}$'],
      \ ['$e^{ x^3}$'])
call vimtex#test#keys('fxdax',
      \ ['$e^{a x^3}$'],
      \ ['$e^{a }$'])

call vimtex#test#keys('2ldax',
      \ ['$\sin_k^{a x^3}$'],
      \ ['$$'])
call vimtex#test#keys('fxdax',
      \ ['$\sin_k^{a x^3}$'],
      \ ['$\sin_k^{a }$'])

call vimtex#test#keys('fadax',
      \ ['$( asd )^{...}$'],
      \ ['$( sd )^{...}$'])
call vimtex#test#keys('f}dax',
      \ ['$( asd )^{...}$'],
      \ ['$$'])

call vimtex#test#keys('fsdax',
      \ ['$\left( asd \right)^{...}$'],
      \ ['$\left( ad \right)^{...}$'])
call vimtex#test#keys('fgdax',
      \ ['$\left( asd \right)^{...}$'],
      \ ['$$'])

quit!
