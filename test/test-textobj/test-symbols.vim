set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

set nomore

setfiletype tex

for [s:keys, s:input, s:expect] in [
      \ ['dax',   '$Cx_0^{1/2} y$',             '$x_0^{1/2} y$'],
      \ ['ldax',  '$Cx_0^{1/2} y$',             '$x_0^{1/2} y$'],
      \ ['lldax', '$Cx_0^{1/2} y$',             '$C y$'],
      \ ['dax',   '$e^{a x^3}$',                '$$'],
      \ ['fadax', '$e^{a x^3}$',                '$e^{ x^3}$'],
      \ ['fxdax', '$e^{a x^3}$',                '$e^{a }$'],
      \ ['2ldax', '$\sin_k^{a x^3}$',           '$$'],
      \ ['fxdax', '$\sin_k^{a x^3}$',           '$\sin_k^{a }$'],
      \ ['fadax', '$( asd )^{...}$',            '$( sd )^{...}$'],
      \ ['f}dax', '$( asd )^{...}$',            '$$'],
      \ ['fsdax', '$\left( asd \right)^{...}$', '$\left( ad \right)^{...}$'],
      \ ['fgdax', '$\left( asd \right)^{...}$', '$$'],
      \]
  call vimtex#test#keys(s:keys, s:input, s:expect)
endfor

call vimtex#test#finished()
