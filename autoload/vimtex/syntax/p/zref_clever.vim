" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#zref_clever#load(cfg) abort " {{{1
  syntax match texCmdZRef "\v\\zc?ref>"
        \ skipwhite skipnl
        \ nextgroup=texZRefArg

  syntax match texCmdZRef "\\zlabel\>"
        \ skipwhite skipnl
        \ nextgroup=texZRefOpt,texRefArg

  call vimtex#syntax#core#new_arg('texZRefArg', {
        \ 'contains': 'texComment,@NoSpell',
        \})
  call vimtex#syntax#core#new_opt('texZRefOpt', {
        \ 'next': 'texRefArg',
        \ 'opts': 'oneline',
        \})

  highlight def link texZRefArg           texRefArg
  highlight def link texZRefOpt           texRefOpt
  highlight def link texCmdZRef           texCmdRef
endfunction

" }}}1
