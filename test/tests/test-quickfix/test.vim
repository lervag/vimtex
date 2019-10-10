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

if empty($MAKE) | finish | endif

call vimtex#qf#setqflist()
let s:qf = getqflist()
call vimtex#test#assert_equal(len(s:qf), 17)

quit!
