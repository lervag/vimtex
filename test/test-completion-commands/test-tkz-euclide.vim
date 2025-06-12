set nocompatible
set runtimepath^=../..
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:vimtex_view_method = "zathura"
let g:vimtex_cache_persistent = v:false

silent edit test-tkz-euclide.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\', 'tkz')
call assert_true(len(s:candidates) > 0)
call assert_equal(s:candidates[0].word, 'tkzAutoLabelPoints')

call vimtex#test#finished()
