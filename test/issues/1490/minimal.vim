set nocompatible
let &rtp = '../../../,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

silent execute "normal GO\\Vim\<c-x>\<c-o>"
silent normal! u
let s:cands = filter(
      \ map(vimtex#complete#omnifunc(0, ''), 'v:val.word'),
      \ 'v:val =~# ''Vimtex''')
call writefile(s:cands, 'cmds.out')

silent execute "normal GO\\begin{Vim\<c-x>\<c-o>"
silent normal! u
let s:cands = filter(
      \ map(vimtex#complete#omnifunc(0, ''), 'v:val.word'),
      \ 'v:val =~# ''Vimtex''')
call writefile(s:cands, 'envs.out')

quitall!
