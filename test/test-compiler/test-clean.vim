set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_compiler_method = 'arara'
let g:vimtex_compiler_clean_paths = [
      \ '_minted*',
      \ 'generated*files*',
      \]

" call vimtex#log#set_silent()

silent edit test-clean.tex

if empty($INMAKE) | finish | endif

silent VimtexClean!

call assert_false(filereadable('test-clean.log'))
call assert_false(filereadable('test-clean.aux'))
call assert_false(filereadable('test-clean.pdf'))
call assert_false(filereadable('generated-extra_files.out'))
call assert_false(isdirectory('_minted-test-clean'))
call assert_false(filereadable('_minted-test-clean/stuffhere'))

call vimtex#test#finished()
