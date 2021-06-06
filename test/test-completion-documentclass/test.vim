set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\documentclass{', 'mini')
call assert_equal(s:candidates[0].word, 'minimal')

call vimtex#test#finished()
