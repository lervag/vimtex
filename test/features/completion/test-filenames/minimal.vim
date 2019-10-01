set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

let s:candidates = vimtex#test#completion('\input{', '')
call vimtex#test#assert(len(s:candidates), 2)

let s:candidates = vimtex#test#completion('\include{', '')
call vimtex#test#assert(s:candidates[0].word, 'main')

let s:candidates = vimtex#test#completion('\includeonly{', '')
call vimtex#test#assert(len(s:candidates), 2)

let s:candidates = vimtex#test#completion('\subfile{', '')
call vimtex#test#assert(s:candidates[1].word, 'tikz_pic.tex')

let s:candidates = vimtex#test#completion('\includegraphics{', '')
call vimtex#test#assert(len(s:candidates), 16)

let s:candidates = vimtex#test#completion('\includegraphics[scale=0.5]{', '')
call vimtex#test#assert(len(s:candidates), 16)

let s:candidates = vimtex#test#completion('\includegraphics[100,100][300,300]{', '')
call vimtex#test#assert(len(s:candidates), 16)

let s:candidates = vimtex#test#completion('\includestandalone{', '')
call vimtex#test#assert(len(s:candidates), 2)

let s:candidates = vimtex#test#completion('\includepdf{', '')
call vimtex#test#assert(s:candidates[0].word, 'figures/fig12.pdf')

quit!
