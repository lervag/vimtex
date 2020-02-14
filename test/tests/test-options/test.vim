set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:progname = get(v:, 'progpath', get(v:, 'progname', ''))
if has('nvim') && executable('nvr')
  let s:progname = 'nvr'
endif

call vimtex#test#assert_equal(g:vimtex_compiler_progname, s:progname)

quit!
