set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

call vimtex#log#set_silent()

let s:cache_name = 'test-write-error'
let s:cache_file = s:cache_name . '.json'
let s:cache = vimtex#cache#open(s:cache_name)
call s:cache.set('bad', "Usuário")
call s:cache.write()

let s:log = vimtex#log#get()
call assert_equal(1, len(s:log))
call assert_equal(
      \ printf('Could not encode cache "%s"', s:cache_name),
      \ s:log[0].msg[0]
      \)

if filereadable(s:cache_file) | call delete(s:cache_file) | endif

call vimtex#test#finished()
