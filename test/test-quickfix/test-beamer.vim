set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit test-beamer.tex

try
  call vimtex#qf#setqflist()
catch /VimTeX: No log file found/
  echo 'VimTeX: No log file found'
  cquit
endtry

let s:qf = getqflist()

call assert_equal(30, s:qf[0].lnum)
call assert_equal('W', s:qf[0].type)
call assert_equal(
      \ 'Overfull \vbox (5.5187pt too high) detected at line 30',
      \ s:qf[0].text)
call assert_equal('test-beamer.tex', bufname(s:qf[0].bufnr))

call vimtex#test#finished()
