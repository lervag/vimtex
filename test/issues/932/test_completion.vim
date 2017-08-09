set nocompatible
let &rtp = '~/.vim/bundle/vimtex,' . &rtp
let &rtp .= ',~/.vim/bundle/vimtex/after'
filetype plugin indent on
syntax enable

silent edit minimal.tex

call feedkeys("8Gf{a\<c-x>\<c-o>\<esc>", 'x')
echo 'Completed 1: ' . matchstr(getline(8), '{\zs.*\ze}') . "\n"

call feedkeys("9Gf{a\<c-x>\<c-o>\<esc>", 'x')
echo 'Completed 2: ' . matchstr(getline(9), '{\zs.\{-}\ze}') . "\n"

quit!
