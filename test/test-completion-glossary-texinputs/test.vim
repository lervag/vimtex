set nocompatible
let &rtp = '../..,' . &rtp
let &rtp .= ',../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:vimtex_cache_persistent = 0

silent edit texwork/example.tex

let s:candidates = vimtex#test#completion('\gls{', '')
call assert_true(len(s:candidates) == 0)

call vimtex#cache#clear('kpsewhich')
call vimtex#cache#clear('texparser')
let $TEXINPUTS = getcwd() . '/texinclude:'
let s:candidates = vimtex#test#completion('\gls{', '')
call assert_true(len(s:candidates) > 0)

call vimtex#test#finished()
