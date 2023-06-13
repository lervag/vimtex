set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

function! Test(file, expected) abort
  silent edit test_auxdir/test.tex
  let l:file = vimtex#paths#shorten_relative(
        \ b:vimtex.compiler.get_file(a:file))
  call assert_equal(a:expected, l:file)
  bwipeout
endfunction

call Test('pdf', 'test.pdf')

let g:vimtex_compiler_latexmk = {'out_dir': 'out'}
call Test('pdf', 'out/test.pdf')
call Test('aux', 'out/test.aux')
call Test('fls', 'out/test.fls')
call Test('log', 'out/test.log')
call Test('blg', 'out/test.blg')

let g:vimtex_compiler_latexmk = {'aux_dir': 'auxfiles'}
call Test('pdf', 'test.pdf')
call Test('fls', 'test.fls')
call Test('aux', 'auxfiles/test.aux')
call Test('log', 'auxfiles/test.log')
call Test('blg', 'auxfiles/test.blg')

let g:vimtex_compiler_latexmk = {
      \ 'out_dir': 'out',
      \ 'aux_dir': 'auxfiles'
      \}
call Test('pdf', 'out/test.pdf')
call Test('fls', 'out/test.fls')
call Test('aux', 'auxfiles/test.aux')
call Test('log', 'auxfiles/test.log')
call Test('blg', 'auxfiles/test.blg')

call vimtex#log#set_silent()
let $VIMTEX_OUTPUT_DIRECTORY = 'out'
call Test('aux', 'out/test.aux')
call Test('log', 'out/test.log')

call vimtex#test#finished()
