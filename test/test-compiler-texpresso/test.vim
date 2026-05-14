set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

let g:vimtex_view_automatic = 0
let g:vimtex_compiler_method = 'texpresso'
call vimtex#log#set_silent()

silent edit test.tex

if empty($INMAKE) | finish | endif

let s:c = b:vimtex.compiler

" Compiler flags
call assert_true(s:c.continuous,
      \ 'texpresso must run in continuous mode')
call assert_true(get(s:c, 'stdin_pipe', 0),
      \ 'stdin_pipe must be set so Vim can write to texpresso stdin')

" Required protocol flags are always present, regardless of user options
let s:cmd = s:c.__build_cmd('')
call assert_match('^texpresso ', s:cmd)
call assert_match('\V-json', s:cmd)
call assert_match('\V-lines', s:cmd)

" User options are appended after the required flags
let g:vimtex_compiler_texpresso = {'options': ['-tectonic']}
bwipeout!
silent edit test.tex
let s:cmd = b:vimtex.compiler.__build_cmd('')
call assert_match('^texpresso -json -lines', s:cmd)
call assert_match('\V-tectonic', s:cmd)

" passed_options are separated from the last flag regardless of leading space
let s:cmd = b:vimtex.compiler.__build_cmd('-extra')
call assert_match('\V-lines -tectonic -extra ', s:cmd)

call vimtex#test#finished()
