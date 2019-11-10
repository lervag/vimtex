set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

let g:tex_flavor = 'latex'

silent edit main.tex

call vimtex#test#assert_equal([
  \ 'main.tex',
  \ 'test/include1.tex',
  \ 'test/sub/include2.tex',
  \], b:vimtex.sources)

quit!
