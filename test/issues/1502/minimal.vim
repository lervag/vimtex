set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:vimtex_fold_enabled = 1
let g:vimtex_fold_types = {
      \ 'markers': {
      \  'open': '<<:',
      \  'close': ':>>',
      \ },
      \}

silent edit minimal.tex
