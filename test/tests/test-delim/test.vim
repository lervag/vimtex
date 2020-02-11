set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on
syntax on

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

silent edit test.tex

normal! G
let s:current = vimtex#delim#get_current('all', 'both')
let s:corresponding = vimtex#delim#get_matching(s:current)
call vimtex#test#assert(s:corresponding.lnum == 1)

quit!
