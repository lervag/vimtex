set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

let g:vimtex_view_automatic = 0
let g:vimtex_compiler_latexmk = {
    \ 'options' : [
    \   '-pdf',
    \   '-shell-escape',
    \   '-verbose',
    \   '-file-line-error',
    \   '-synctex=1',
    \   '-interaction=nonstopmode',
    \    '-f',
    \ ],
    \}

if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

silent edit minimal.tex

normal! 17G
execute "normal A\\gls{\<c-x>\<c-o>"
