set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

silent edit plaintex.tex
call vimtex#test#assert_equal('tex', &filetype)

quit!
