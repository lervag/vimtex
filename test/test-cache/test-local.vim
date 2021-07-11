set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

" Local caches
let s:cache1 = vimtex#cache#open('test-local', {'local': 1})
call assert_equal('./test-local.json', s:cache1.path)
call s:cache1.set('a', 1)

" Local caches (this is a new cache)
let b:vimtex = {'tex': '/foo.bar'}
let s:cache2 = vimtex#cache#open('test-local', {'local': 1})
call assert_equal('./test-local%foo.json', s:cache2.path)
call s:cache2.set('a', 2)

" The caches are not the same!
call vimtex#cache#write_all()
call assert_true(s:cache1.path !=# s:cache2.path)

" Clean up
call delete(s:cache1.path)
call delete(s:cache2.path)

call vimtex#test#finished()
