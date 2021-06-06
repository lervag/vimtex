let g:tex_flavor = 'plain'

set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

silent edit plaintex.tex
call assert_equal('plaintex', &filetype)

call vimtex#test#finished()
