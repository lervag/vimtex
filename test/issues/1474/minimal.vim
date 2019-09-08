set nocompatible
let &rtp = '~/.vim/plugged/vimtex,' . &rtp
let &rtp .= ',~/.vim/plugged/vimtex/after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'
let g:vimtex_complete_enabled = 1
let g:vimtex_view_automatic = 0
let g:vimtex_fold_enabled = 1

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
