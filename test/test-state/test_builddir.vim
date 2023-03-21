set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

function! TestBuildDir(expected) abort
  silent edit test.tex
  " let l:out_dir = vimtex#paths#shorten_relative(
  "       \ fnamemodify(b:vimtex.compiler.get_file('pdf'), ':h'))
  call assert_equal(a:expected, b:vimtex.compiler.out_dir)
  bwipeout
endfunction

call TestBuildDir('')

let g:vimtex_compiler_latexmk = {'out_dir': 'out'}
call TestBuildDir('out')

let $VIMTEX_OUTPUT_DIRECTORY = 'out'
call TestBuildDir('out')
call assert_true(empty(vimtex#log#get()))

let $VIMTEX_OUTPUT_DIRECTORY = 'build'
call TestBuildDir('build')
let s:warning = get(map(vimtex#log#get(), {_, x -> x.msg[0]}), 0, 'NONE')
call assert_equal(
      \ 'Setting VIMTEX_OUTPUT_DIRECTORY overrides out_dir!',
      \ s:warning)

let $VIMTEX_OUTPUT_DIRECTORY = ''
call TestBuildDir('out')

call vimtex#test#finished()
