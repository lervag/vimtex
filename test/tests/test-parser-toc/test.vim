set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

" Windows allows filenames to include { and }
" Issue: https://github.com/lervag/vimtex/issues/1543
set isfname+={,}

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:parsed = vimtex#parser#toc()
call vimtex#test#assert_equal(len(s:parsed), 10)

" Test added for #1543
call vimtex#test#assert_equal(s:parsed[6].type, 'include')
call vimtex#test#assert_equal(s:parsed[6].file, 'sub.tex')

quit!
