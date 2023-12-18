set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit test-starred.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()
call assert_equal(11, len(s:toc))

for [index, level, nstring] in [
      \ [1, 0, '1'],
      \ [2, 1, '1.1'],
      \ [3, 5, ''],
      \ [4, 0, ''],
      \ [5, 1, ''],
      \ [6, 5, ''],
      \ [7, 1, '1.2'],
      \ [8, 5, ''],
      \ [9, 0, ''],
      \ [10, 1, ''],
      \]
  call assert_equal(level, s:toc[index].level)
  call assert_equal(nstring, b:vimtex.toc.print_number(s:toc[index].number))
endfor

call vimtex#test#finished()
