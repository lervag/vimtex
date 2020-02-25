set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'
" let g:vimtex_cache_persistent = 1

" Test existing cache
let s:cache = vimtex#cache#open('test4', {'default': {'key': 1}})
call vimtex#test#assert_equal(s:cache.get('a').key, 2)

" Disable persistence
let s:cache.persistent = 0

" Test dictionary property
let s:current = s:cache.get('missing')
let s:current.other = 1
call vimtex#test#assert_equal(s:current.key, 1)

let s:again = s:cache.get('missing')
call vimtex#test#assert_equal(get(s:again, 'other'), 1)

quit!
