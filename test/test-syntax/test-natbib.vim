source common.vim

highlight texCmdRef ctermfg=6 guifg=cyan
highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue

" let g:vimtex_syntax_conceal_cites = {
"       \ 'type': 'icon',
"       \}

silent edit test-natbib.tex

split
silent wincmd w
set conceallevel=2

if empty($INMAKE) | finish | endif
quitall!
