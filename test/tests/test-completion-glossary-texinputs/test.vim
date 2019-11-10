set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

silent edit texwork/example.tex

let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert(len(s:candidates) == 0)

let $TEXINPUTS = getcwd() . '/texinclude:'
let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert(len(s:candidates) > 0)

quit!
