set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit test1.tex

if empty($INMAKE) | finish | endif

" Test custom commands
let s:candidates = vimtex#test#completion('\', 'test')
call assert_true(len(s:candidates) > 0)
call assert_equal(s:candidates[0].word, 'testddc')
call assert_equal(s:candidates[1].word, 'testnewcommand')
call assert_equal(s:candidates[2].word, 'testlet')

" Test commands from packages (xparse in this case)
let s:candidates = vimtex#test#completion('\', 'DeclareD')
call assert_true(len(s:candidates) > 0)
call assert_equal(s:candidates[0].word, 'DeclareDocumentCommand')

" Test commands from custom glossaries
let s:candidates = vimtex#test#completion('\', 'glsentry.*acc')
call assert_true(len(s:candidates) > 0)
call assert_equal(s:candidates[0].word, 'glsentrymaccusative')

call vimtex#test#finished()
