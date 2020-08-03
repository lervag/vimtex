set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

let g:vimtex_log_verbose = 0

nnoremap q :qall!<cr>

function! Test() abort
  silent edit plaintex.tex
  let l:entries = vimtex#log#get()
  call vimtex#test#assert_equal(1, len(l:entries))
  call vimtex#test#assert_equal('g:tex_flavor not specified', l:entries[0].msg[0])
  quit!
endfunction

autocmd VimEnter * call Test()
