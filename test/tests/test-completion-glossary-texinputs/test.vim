set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

let g:vimtex_cache_root = '.'

silent edit texwork/example.tex

let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert(len(s:candidates) == 0)

call vimtex#cache#clear('kpsewhich')
let $TEXINPUTS = getcwd() . '/texinclude:'
let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert(len(s:candidates) > 0)

quit!
