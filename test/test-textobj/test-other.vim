set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on
syntax on

set nomore

setfiletype tex

call vimtex#test#keys('02f+d2ac',
      \ ['a + \bar{\mathit{c + d}} ='],
      \ ['a +  ='])

call vimtex#test#keys('fdd2ad',
      \ ['a + \left(b + \left[c + d \right] + e\right) + f'],
      \ ['a +  + f'])

call vimtex#test#keys('f\dac',
      \ ['a + \test[opt1][opt2]{arg} + f'],
      \ ['a +  + f'])

call vimtex#test#keys('f\dac',
      \ ['a + \; f'],
      \ ['a +  f'])

call vimtex#test#finished()
