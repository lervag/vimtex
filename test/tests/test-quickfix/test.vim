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
let s:qf_len = len(s:qf)
call vimtex#test#assert(s:qf_len >= 15)

" Apply ignore filters
let g:vimtex_quickfix_ignore_filters = ['\\test']
call vimtex#qf#setqflist()
let s:qf = getqflist()
call vimtex#test#assert(len(s:qf) == s:qf_len - 1)

" Repeated invocations should not create extra quickfix lists
try
  let s:qf_nr = getqflist({'nr':'$'}).nr
  call vimtex#test#assert(s:qf_nr == 1)
catch
endtry

quitall!
