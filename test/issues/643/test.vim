set nocompatible
let &rtp  = '~/.vim/bundle/vimtex,' . &rtp
let &rtp .= ',~/.vim/bundle/vimtex/after'
filetype plugin indent on
syntax enable

" let g:vimtex_indent_delims_type = 'complex'

silent edit test.tex
profile start test.log
profile func *
profile file *
silent! normal! gg=G
profile pause
quit!
