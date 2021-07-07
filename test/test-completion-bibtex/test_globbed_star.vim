set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

let s:tex_filename = expand('<sfile>:r') . '.tex'
silent execute 'edit' s:tex_filename

if empty($INMAKE) | finish | endif

" calls files_manual when no bcf file for tex file found
let s:candidates = vimtex#test#completion('\cite{', '')
call assert_equal(3, len(s:candidates))

bwipeout!
call vimtex#test#finished()
