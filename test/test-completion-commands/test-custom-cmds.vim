set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

silent edit test-custom-cmds.tex

if empty($INMAKE) | finish | endif

" Test custom commands
let s:candidates = vimtex#test#completion('\', 'test')
call assert_equal(4, len(s:candidates))
call assert_equal('testddc', s:candidates[0].word)
call assert_equal('testnewcommand', s:candidates[1].word)
call assert_equal('testpaireddelim', s:candidates[2].word)
call assert_equal('testlet', s:candidates[3].word)

" Test commands from packages (xparse in this case)
let s:candidates = vimtex#test#completion('\', 'DeclareD')
call assert_true(len(s:candidates) > 0)
call assert_equal(s:candidates[0].word, 'DeclareDocumentCommand')

" Test commands from custom glossaries
let s:candidates = vimtex#test#completion('\', 'glsentry.*acc')
call assert_true(len(s:candidates) > 0)
call assert_equal(s:candidates[0].word, 'glsentrymaccusative')

call vimtex#test#finished()
