set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit $TEXFILE

let s:candidates = vimtex#test#completion('\gls{', '')
call assert_equal(10, len(s:candidates))

call vimtex#test#finished()
