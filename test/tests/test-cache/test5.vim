set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

" Local caches (no b:vimtex.tex)
let s:cache1 = vimtex#cache#open('test5', {'local': 1})
call s:cache1.set('d', 4)
call vimtex#cache#write_all()

" Local caches (this is a new cache)
let b:vimtex = {'tex': 'test-path'}
let s:cache2 = vimtex#cache#open('test5', {'local': 1})
call s:cache2.set('a', 1)
call vimtex#cache#write_all()

call vimtex#test#assert(s:cache1.path !=# s:cache2.path)
call delete(s:cache1.path)
call delete(s:cache2.path)

quit!
