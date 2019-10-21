set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

set nomore

if empty($INMAKE)
  edit main.tex
  finish
else
  silent edit main.tex
endif

let s:warnings = vimtex#log#get()
call vimtex#test#assert_equal(len(s:warnings), 1)
call vimtex#test#assert_match(join(s:warnings[0].msg), 'pdf_mode.*inconsistent')

quit!
