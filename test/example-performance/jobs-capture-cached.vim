set nocompatible
set runtimepath^=~/.local/plugged/vimtex
filetype plugin on

nnoremap q :qall!<cr>

let s:cmd = 'uname -sr'

let s:time = vimtex#profile#time()
for s:x in range(100)
  call vimtex#jobs#capture(s:cmd)
endfor

let s:time = vimtex#profile#time(s:time)
for s:x in range(100)
  call vimtex#jobs#cached(s:cmd)
endfor

call vimtex#profile#time(s:time)

quitall!
