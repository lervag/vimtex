source common.vim

highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue

let g:vimtex_syntax_conceal_cites = {
      \ 'type': 'brackets',
      \}

silent edit test-biblatex.tex

split
silent wincmd w
set conceallevel=2

if empty($INMAKE) | finish | endif
quit!
