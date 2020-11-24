set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test.tex

if empty($INMAKE) | finish | endif

try
  let s:cmd = vimtex#cmd#get_next()
  call vimtex#test#assert(s:cmd.name ==# '\begin')
catch
  echo 'Failed to parse command!'
  echo getline('.') "\n"
  cquit
endtry

quit!
