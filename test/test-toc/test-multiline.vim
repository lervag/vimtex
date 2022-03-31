set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

set foldenable
let g:vimtex_fold_enabled = 1

silent edit test-multiline.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()
call assert_equal(3, len(s:toc))
call assert_equal(
      \ 'This is a really long section title which is hard-wrapped after '
      \ . '80 characters or so to keep the source code readable',
      \ s:toc[2].title)

call vimtex#test#finished()
