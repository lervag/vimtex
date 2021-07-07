set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

let g:status = 0
nnoremap q :qall!<cr>

let g:vimtex_compiler_latexmk = {'build_dir': 'build'}

call vimtex#log#set_silent()

augroup test_builddir
  autocmd!
  autocmd User VimtexEventCompileSuccess let g:status = 1
  autocmd User VimtexEventCompileFailed let g:status = 2
augroup END

silent edit test-builddir.tex

if empty($INMAKE) | finish | endif

silent VimtexCompileSS

let s:n = 0
while g:status < 1 && s:n < 100
  sleep 20m
  let s:n += 1
endwhile

call assert_equal(2, g:status)

silent VimtexClean!
call vimtex#test#finished()
