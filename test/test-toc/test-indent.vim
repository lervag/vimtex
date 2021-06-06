set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_toc_config = {'indent_levels': 1, 'hotkeys_enabled': 1}

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()

let b:vimtex.toc.number_width = 4
let b:vimtex.toc.number_format = '%-4s'
call b:vimtex.toc.print_entry(s:toc[6])

call assert_equal('L1 [al]   2.1 The first section', getline('$'))

call vimtex#test#finished()
