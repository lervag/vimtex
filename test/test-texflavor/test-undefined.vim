set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

silent edit plaintex.tex
call assert_equal('tex', &filetype)

call vimtex#test#finished()
