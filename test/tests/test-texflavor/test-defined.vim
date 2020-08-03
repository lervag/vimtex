set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

let g:tex_flavor = 3
let g:vimtex_log_verbose = 0

nnoremap q :qall!<cr>

function! Test() abort
  silent edit plaintex.tex
  let l:entries = vimtex#log#get()
  call vimtex#test#assert_equal(0, len(l:entries))
  quit!
endfunction

autocmd VimEnter * call Test()
