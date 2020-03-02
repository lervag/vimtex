set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin on
syntax enable

set nomore

nnoremap q :qall!<cr>

silent edit test-loading.tex

call vimtex#test#assert(index(keys(b:vimtex_syntax), 'glossaries') >= 0)
call vimtex#test#assert(index(keys(b:vimtex_syntax), 'amsmath') >= 0)

quit!
