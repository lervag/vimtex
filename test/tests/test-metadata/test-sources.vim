set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

let g:tex_flavor = 'latex'

silent edit test-sources/main.tex

call vimtex#test#assert_equal([
  \ 'main.tex',
  \ 'include1.tex',
  \ 'sub1/include2.tex',
  \ 'sub2/include3.tex',
  \ 'subfile.tex',
  \], b:vimtex.sources)

quit!
