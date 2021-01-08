set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

set nomore

let g:vimtex_view_automatic = 0

if empty($INMAKE)
  edit main.tex
  finish
else
  silent edit main.tex
endif

call vimtex#test#assert_equal('-pdfps', b:vimtex.compiler.get_engine())

quit!
