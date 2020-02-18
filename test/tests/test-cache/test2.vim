set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

let s:cache = vimtex#cache#open('test2')

call s:cache.insert('a', 1)
call s:cache.insert('b', 2)
call s:cache.insert('c', 3)
call s:cache.insert('d', 4)
call vimtex#test#assert_equal(s:cache.get('d'), 4)

call s:cache.update('d', 5)
call vimtex#test#assert_equal(s:cache.get('d'), 5)

call delete('test2.json')
quit!
