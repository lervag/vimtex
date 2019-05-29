set nocompatible
let &rtp = '~/.vim/bundle/vimtex,' . &rtp
let &rtp .= ',~/.vim/bundle/vimtex/after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

" let g:vimtex_fold_enabled = 1

call vimtex#profile#file('some_file')

" E.g.:
" 'FUNCTION  vimtex#fold#level(',
call vimtex#profile#filter([
      \ 'FUNCTIONS SORTED ON SELF',
      \ 'FUNCTIONS SORTED ON TOTAL',
      \])

call vimtex#profile#print()
" call vimtex#profile#open()
