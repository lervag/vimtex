set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_toc_custom_matchers = [
      \ { 'title' : 'My Custom Environment',
      \   're' : '\v^\s*\\begin\{quote\}' }
      \]

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()
call vimtex#test#assert_equal(len(s:toc), 8)

quit!
