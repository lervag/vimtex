set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

" Test custom commands
let s:candidates = vimtex#test#completion('\', 'test')
call vimtex#test#assert_equal(s:candidates[0].word, 'testddc')
call vimtex#test#assert_equal(s:candidates[1].word, 'testnewcommand')
call vimtex#test#assert_equal(s:candidates[2].word, 'testlet')

" Test commands from packages (xparse in this case)
let s:candidates = vimtex#test#completion('\', 'DeclareD')
call vimtex#test#assert_equal(s:candidates[0].word, 'DeclareDocumentCommand')

quit!
