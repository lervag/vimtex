set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit test-fixme.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()
let s:envs = filter(deepcopy(s:toc), {_, x -> x.title =~# '^anfx'})
let s:cmds = filter(deepcopy(s:toc), {_, x -> x.title =~# '^fx'})

" let s:i = 0
" for s:x in s:cmds
"   echo s:i '--' s:x.title "\n"
"   let s:i += 1
" endfor

call assert_equal(8, len(s:envs))
call assert_equal(8, len(s:cmds))

call vimtex#test#finished()
