set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

let s:candidates = vimtex#test#completion('\documentclass{', '^mini')
call vimtex#test#assert_equal(s:candidates[0].word, 'minimal')

quit!
