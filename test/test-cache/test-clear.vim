set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

" Clear global cache
let s:cache = vimtex#cache#open('test-clear')
call assert_equal('./test-clear.json', s:cache.path)
call s:cache.set('a', 1)
call assert_true(s:cache.has('a'))
call assert_true(filereadable(s:cache.path))
call s:cache.clear()
call assert_false(s:cache.has('a'))
call assert_false(filereadable(s:cache.path))

" Clear local cache
let b:vimtex = {'tex': '/foobar.tex'}
let s:cache = vimtex#cache#open('test-clear', {'local': 1})
call assert_equal('./test-clear%foobar.json', s:cache.path)
call s:cache.set('a', 1)
call assert_true(s:cache.has('a'))
call assert_true(filereadable(s:cache.path))
call s:cache.clear()
call assert_false(s:cache.has('a'))
call assert_false(filereadable(s:cache.path))

call vimtex#test#finished()
