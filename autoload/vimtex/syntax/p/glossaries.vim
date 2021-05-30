" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#glossaries#load(cfg) abort " {{{1
  syntax match texCmd nextgroup=texGlsArg skipwhite skipnl "\\gls\>"
  call vimtex#syntax#core#new_arg('texGlsArg', {'contains': '@NoSpell'})

  " \newacronym -> opt -> arg1 -> arg2 -> arg3
  syntax match texCmdNewAcr "\\newacronym\>"
        \ nextgroup=texNewAcrOpt,texNewAcrArgLabel skipwhite skipnl
  call vimtex#syntax#core#new_opt('texNewAcrOpt', {
        \ 'next': 'texNewAcrArgLabel',
        \})
  call vimtex#syntax#core#new_arg('texNewAcrArgLabel', {
        \ 'next': 'texNewAcrArgAbbr',
        \ 'contains': '@NoSpell',
        \})
  call vimtex#syntax#core#new_arg('texNewAcrArgAbbr', {
        \ 'next': 'texNewAcrArgLong',
        \ 'contains': '@NoSpell',
        \})
  call vimtex#syntax#core#new_arg('texNewAcrArgLong')

  " \acrcmds -> ArgLabel
  syntax match texCmdAcr
        \ "\v\\%(ACR|Acr|acr)%(full|long|short)%(pl)?>"
        \ nextgroup=texAcrArgLabel skipwhite skipnl
  syntax match texCmdAcr "\\acrfullfmt"
        \ nextgroup=texAcrArgLabel skipwhite skipnl
  call vimtex#syntax#core#new_arg('texAcrArgLabel', {'contains': '@NoSpell'})

  highlight def link texCmdAcr         texCmd
  highlight def link texCmdNewAcr      texCmdNew
  highlight def link texNewAcrOpt      texOpt
  highlight def link texNewAcrArgLabel texArg
  highlight def link texAcrArgLabel    texNewAcrArgLabel
endfunction

" }}}1
