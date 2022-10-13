set nocompatible
set runtimepath^=../..
filetype plugin on

nnoremap q :qall!<cr>

let g:test = 0

function! Callback(msg)
  if a:msg =~# 'SillyWalk'
    let g:test = 1
  endif
endfunction

let g:vimtex_view_automatic = 0
let g:vimtex_compiler_method = 'generic'
let g:vimtex_compiler_generic = {
      \ 'command': 'make dummy',
      \ 'hooks': [function('Callback')],
      \}

call vimtex#log#set_silent()

silent edit test.tex

if empty($INMAKE) | finish | endif

call vimtex#compiler#start()
call b:vimtex.compiler.wait()
call assert_equal(1, g:test)

call vimtex#test#finished()
