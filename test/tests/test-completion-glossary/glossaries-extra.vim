set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit $TEXFILE

let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert_equal(len(s:candidates), 9)

quit!
