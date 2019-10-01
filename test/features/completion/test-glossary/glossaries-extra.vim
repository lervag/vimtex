set nocompatible
let &rtp = '../../../..,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit $TEXFILE

let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert(len(s:candidates), 9)

quit!
