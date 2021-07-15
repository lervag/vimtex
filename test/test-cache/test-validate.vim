set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_cache_root = '.'

" Create test files
let s:files = {
      \ 'test-validate-pass.json': {'__validate': 1, 'a': 1},
      \ 'test-validate-fail.json': {'__validate': 0, 'a': 1},
      \}
for [s:file, s:content] in items(s:files)
  call writefile([json_encode(s:content)], s:file)
endfor


let s:cache = vimtex#cache#open('test-validate-pass', {'validate': 1})
call assert_true(s:cache.has('a'))

let s:cache = vimtex#cache#open('test-validate-fail', {'validate': 1})
call assert_false(s:cache.has('a'))


" Clean up
for s:file in keys(s:files)
  if filereadable(s:file) | call delete(s:file) | endif
endfor

call vimtex#test#finished()
