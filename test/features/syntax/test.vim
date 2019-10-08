set nocompatible
let &rtp = '.,' . &rtp
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin on
syntax enable

nnoremap q :qall!<cr>

" Use a more colorful colorscheme
colorscheme morning

let g:tex_flavor = 'latex'
let g:vimtex_fold_enabled = 1
let g:vimtex_echo_ignore_wait = 1

function! SynNames()
  return join(map(synstack(line('.'), col('.')),
        \ 'synIDattr(v:val, ''name'')'), ' -> ')
endfunction

augroup Testing
  autocmd!
  autocmd CursorMoved * echo SynNames()
augroup END

silent edit test-syntax.tex
