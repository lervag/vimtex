set nocompatible
let &rtp = '../..,' . &rtp

if !has('nvim')
  call vimtex#test#finished()
endif

if empty($INMAKE) | finish | endif

let s:path_save = $PATH
let s:fake_dir = tempname()
let s:protocol = s:fake_dir . '/protocol.log'
call mkdir(s:fake_dir, 'p')
call writefile([
      \ '#!/bin/sh',
      \ ': > ' . shellescape(s:protocol),
      \ 'while IFS= read -r line; do',
      \ '  printf "%s\n" "$line" >> ' . shellescape(s:protocol),
      \ 'done',
      \], s:fake_dir . '/texpresso')
call setfperm(s:fake_dir . '/texpresso', 'rwxr-xr-x')
let $PATH = s:fake_dir . ':' . $PATH

filetype plugin on

let g:vimtex_view_automatic = 0
let g:vimtex_compiler_method = 'texpresso'
call vimtex#log#set_silent()

silent edit test.tex

try
  set termguicolors
  highlight Normal guifg=#ffffff guibg=#000000
  call vimtex#compiler#start()
  sleep 100m

  call append(1, 'protocol line')
  call cursor(1, 1)
  call b:vimtex.compiler.texpresso_synctex_forward()
  call b:vimtex.compiler.texpresso_previous_page()
  call b:vimtex.compiler.texpresso_next_page()
  sleep 100m

  call vimtex#compiler#stop()
  sleep 50m

  let s:messages = map(readfile(s:protocol), 'json_decode(v:val)')
  let s:names = map(copy(s:messages), 'v:val[0]')
  for s:name in [
        \ 'open',
        \ 'theme',
        \ 'change-lines',
        \ 'synctex-forward',
        \ 'previous-page',
        \ 'next-page',
        \]
    call assert_true(index(s:names, s:name) >= 0,
          \ 'expected protocol message: ' . s:name)
  endfor
finally
  let $PATH = s:path_save
  call delete(s:fake_dir, 'rf')
endtry

call vimtex#test#finished()
