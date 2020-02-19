set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

let s:cache = vimtex#cache#open('test2', {'persistent': 0})

call s:cache.set('a', 1)
call s:cache.set('b', 2)
call s:cache.set('c', 3)
call s:cache.set('d', 4)
call vimtex#test#assert_equal(s:cache.get('d'), 4)

call s:cache.set('d', 5)
call vimtex#test#assert_equal(s:cache.get('d'), 5)

quit!
