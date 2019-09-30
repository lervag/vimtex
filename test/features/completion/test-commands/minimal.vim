set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

" Test custom commands
let s:candidates = vimtex#test#completion('\', 'test')
call vimtex#test#assert(s:candidates[0].word, 'testddc')
call vimtex#test#assert(s:candidates[1].word, 'testnewcommand')
call vimtex#test#assert(s:candidates[2].word, 'testlet')

" Test commands from packages (xparse in this case)
let s:candidates = vimtex#test#completion('\', 'DeclareD')
call vimtex#test#assert(s:candidates[0].word, 'DeclareDocumentCommand')

quit!
