set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

set nomore

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

let s:candidates = vimtex#test#completion('\bibliographystyle{', '')
call vimtex#test#assert(index(map(s:candidates, 'v:val.word'), 'unsrt') > 0, v:true)

quit!
