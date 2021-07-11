set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

function! SlowFunc(argument) abort
  sleep 100m
  return a:argument + 100
endfunction
let SlowFuncWrapped = vimtex#cache#wrap(
      \ function('SlowFunc'), 'test-wrapper', {'persistent': 0})

" First call is slow
let s:time = reltime()
call assert_equal(101, SlowFuncWrapped(1))
call assert_inrange(0.09, 0.11, reltimefloat(reltime(s:time)))

" Second call is fast
let s:time = reltime()
call assert_equal(101, SlowFuncWrapped(1))
call assert_inrange(0.0, 0.01, reltimefloat(reltime(s:time)))

" We can also open the cache directly
let s:cache = vimtex#cache#open('test-wrapper')
call assert_true(s:cache.has(1))

call vimtex#test#finished()
