set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0

let g:vimtex_complete_bib = {
      \ 'bibliography_commands': [
      \   'mybibliography',
      \ ]
      \}

silent edit test_custom_bibs.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\cite*{', '')
call vimtex#test#assert(len(s:candidates) > 0)

quit!
