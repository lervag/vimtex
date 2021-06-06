set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

function! SlowFunc(argument) abort
  sleep 100m
  return a:argument
endfunction

let SlowFuncWrapped = vimtex#cache#wrap(
      \ function('SlowFunc'), 'test3', {'persistent': 0})
call SlowFuncWrapped(1)

call assert_true(SlowFuncWrapped(1) == 1)

let s:cache = vimtex#cache#open('test3')
call assert_true(s:cache.has(1))

call vimtex#test#finished()
