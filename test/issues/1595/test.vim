set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>
nnoremap <nowait> f :cquit!<cr>

let g:vimtex_view_automatic = 0

function! Test() abort
  normal! $
  VimtexCompile
endfunction

augroup vimrc
  autocmd!
  autocmd vimrc VimEnter * call Test()
augroup END
