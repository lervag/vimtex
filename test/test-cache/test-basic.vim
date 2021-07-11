set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'


" Test basic open and read
let s:cache = vimtex#cache#open('test-basic')
call assert_equal(1, s:cache.get('a'))
call assert_equal(4, s:cache.get('d'))
call assert_equal(0, s:cache.get('missing'))
call assert_true(s:cache.has('c'))
call vimtex#cache#close('test-basic')


" Similar, but now change default value
let s:cache = vimtex#cache#open('test-basic', {'default': {'key': 1}})
call s:cache.read()
let s:cache.persistent = 0
let s:current = s:cache.get('missing')
call assert_equal({'key': 1}, s:current)
let s:current.other = 1
let s:again = s:cache.get('missing')
call assert_equal(1, get(s:again, 'other'))


" Test create, set and overwrite - non persistent
let s:cache = vimtex#cache#open('test-new', {'persistent': 0})
call s:cache.set('a', 1)
call s:cache.set('b', 2)
call s:cache.set('c', 3)
call s:cache.set('d', 4)
call assert_equal(4, s:cache.get('d'))
call s:cache.set('d', 5)
call assert_equal(5, s:cache.get('d'))
call assert_true(!filereadable('test-new.json'))


call vimtex#test#finished()
