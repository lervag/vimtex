source common.vim

" let g:vimtex_syntax_conceal_cites = {
"       \ 'type': 'icon',
"       \}

EditConcealed! test-biblatex-chicago.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
