set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

set nomore

let g:tex_flavor = 'latex'

silent edit main.tex

if empty($INMAKE) | finish | endif

try
  silent call vimtex#qf#setqflist()
catch /Vimtex: No log file found/
  echo 'Vimtex: No log file found'
  cquit
endtry

let s:qf = getqflist()
call vimtex#test#assert(len(s:qf) == 2)
call vimtex#test#assert_equal(bufname(s:qf[1].bufnr), './test.tex')"}}}

quit!
