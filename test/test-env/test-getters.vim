set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-getters.tex

normal! 8G
call assert_equal(['y', 'x'], map(vimtex#env#get_all(), 'v:val.name'))
call assert_equal('y', vimtex#env#get_inner().name)
call assert_equal('x', vimtex#env#get_outer().name)

" Simple profiling
" let s:t0 = vimtex#profile#time()
" for s:i in range(100)
"   call vimtex#env#get_all()
" endfor
" call vimtex#profile#time(s:t0)

call vimtex#test#finished()
