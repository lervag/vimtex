set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()

let b:vimtex.toc.number_width = 4
let b:vimtex.toc.number_format = '%-4s'
call b:vimtex.toc.print_entry(s:toc[12])

call assert_equal('L1 3.1 $L^p$ spaces', getline('$'))

call vimtex#test#finished()
