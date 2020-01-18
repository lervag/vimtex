set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

set nomore

let g:tex_flavor = 'latex'

let g:vimtex_view_automatic = 0
if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

silent edit file\ with\ errors.tex

if empty($INMAKE) | finish | endif

try
  call vimtex#qf#setqflist()
catch /Vimtex: No log file found/
  echo 'Vimtex: No log file found'
  cquit
endtry

let s:qf = getqflist()
call vimtex#test#assert(len(s:qf) >= 15)

" Repeated uses should not create extra quickfix lists
call vimtex#qf#setqflist()
call vimtex#test#assert(getqflist({'nr':'$'}).nr == 1)

quitall!
