set nocompatible
let &rtp = '.,' . &rtp
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin on
syntax enable

set nomore

nnoremap q :qall!<cr>

" Use a more colorful colorscheme
colorscheme morning

let g:tex_flavor = 'latex'
let g:vimtex_fold_enabled = 1

function! SynNames()
  return join(map(synstack(line('.'), col('.')),
        \ 'synIDattr(v:val, ''name'')'), ' -> ')
endfunction

silent edit minimal.tex

if empty($INMAKE)
  augroup Testing
    autocmd!
    autocmd CursorMoved * echo SynNames()
  augroup END

  finish
endif

call vimtex#test#assert_equal(len(keys(b:vimtex_syntax)), 21)

quit!
