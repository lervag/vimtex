set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax enable

set nomore

nnoremap q :qall!<cr>

silent edit test-cites.tex

if empty($INMAKE) | finish | endif

" Check validity of a single entry
let s:handler = vimtex#context#get(9, 49).handler
call assert_equal('Hemingway1940', s:handler.selected)
let s:actions = s:handler.get_actions()
call assert_equal(9, len(s:actions.entry))

" Check that we get the right key of another entry at a "difficult" spot
call assert_equal('JiM2020', vimtex#context#get(11, 39).handler.selected)

" Check that arxiv handler is available
call assert_equal('Open arXiv',
      \ vimtex#context#get(14, 14).handler.get_actions().menu[3].name)
call assert_equal('Open arXiv',
      \ vimtex#context#get(14, 39).handler.get_actions().menu[2].name)

call vimtex#test#finished()
