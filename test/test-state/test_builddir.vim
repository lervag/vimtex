set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

function! TestBuildDir(expected) abort
  silent edit test.tex
  let l:build_dir = vimtex#paths#shorten_relative(
        \ fnamemodify(b:vimtex.ext('dummy', 1), ':h'))
  call assert_equal(a:expected, l:build_dir)
  bwipeout
endfunction

call TestBuildDir('')

let g:vimtex_compiler_latexmk = {'build_dir': 'out'}
call TestBuildDir('out')

let $VIMTEX_OUTPUT_DIRECTORY = 'out'
call TestBuildDir('out')
call assert_true(empty(vimtex#log#get()))

let $VIMTEX_OUTPUT_DIRECTORY = 'build'
call TestBuildDir('build')
let s:warning = get(map(vimtex#log#get(), {_, x -> x.msg[0]}), 0, 'NONE')
call assert_equal(
      \ 'Setting VIMTEX_OUTPUT_DIRECTORY overrides build_dir!',
      \ s:warning)

let $VIMTEX_OUTPUT_DIRECTORY = ''
call TestBuildDir('out')

call vimtex#test#finished()
