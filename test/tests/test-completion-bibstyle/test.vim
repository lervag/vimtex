set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\bibliographystyle{', '')
call vimtex#test#assert_equal(
      \ index(map(s:candidates, 'v:val.word'), 'unsrt') > 0, v:true)

quit!
