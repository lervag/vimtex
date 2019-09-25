set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:vimtex_view_method = 'zathura'
let g:vimtex_view_automatic = 0

if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

silent edit minimal.tex

silent execute "normal 4GA\<c-x>\<c-o>"
silent normal! u

echo map(vimtex#complete#omnifunc(0, 'bar'), 'v:val.word')
echo map(vimtex#complete#omnifunc(0, ''),    'v:val.word')

quitall!
