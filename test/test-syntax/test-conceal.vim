source common.vim

highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue

let g:vimtex_syntax_conceal = {'sections': 1}
let g:vimtex_syntax_custom_cmds = [
      \ {'name': 'keyw', 'mathmode': 0, 'argstyle': 'boldital' , 'conceal': 1},
      \]

silent edit test-conceal.tex

vsplit
silent wincmd w
silent windo set scrollbind
set conceallevel=2

if empty($INMAKE) | finish | endif
quitall!
