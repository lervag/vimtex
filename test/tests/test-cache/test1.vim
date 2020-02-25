set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

" Test existing cache
let s:cache = vimtex#cache#open('test1')
call vimtex#test#assert_equal(s:cache.get('a'), 1)
call vimtex#test#assert_equal(s:cache.get('d'), 4)
call vimtex#test#assert_equal(s:cache.get('missing'), 0)
call vimtex#test#assert(s:cache.has('c'))

quit!
