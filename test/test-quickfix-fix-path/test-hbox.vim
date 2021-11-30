set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

set nomore

silent edit test-hbox.tex

if empty($INMAKE) | finish | endif

try
  silent call vimtex#qf#setqflist()
catch /VimTeX: No log file found/
  echo 'VimTeX: No log file found'
  cquit
endtry

let s:qf = getqflist()
call assert_equal(5, len(s:qf))
call assert_equal('./test-hbox-1.tex', bufname(s:qf[1].bufnr))
call assert_equal('./test-hbox-1.tex', bufname(s:qf[2].bufnr))
call assert_equal('test-hbox-2.tex', bufname(s:qf[3].bufnr))
call assert_equal('test-hbox-3.tex', bufname(s:qf[4].bufnr))

call vimtex#test#finished()
