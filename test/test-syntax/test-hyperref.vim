source common.vim

highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue
" let g:vimtex_syntax_conceal_disable = 1

silent edit test-hyperref.tex

vsplit
silent wincmd w
silent windo set scrollbind
set conceallevel=2

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texUrlArg', 6, 25))
call assert_true(vimtex#syntax#in('texRefArg', 17, 35))

call vimtex#test#finished()
