" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#hyperref#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('nameref')

  syntax match texCmdHyperref '\\autoref\>'
        \ skipwhite nextgroup=texRefOpt,texRefArg

  syntax match texCmdHyperref '\\hyperref\>'
        \ skipwhite nextgroup=texHyperrefLink,texHyperrefText
  call vimtex#syntax#core#new_opt('texHyperrefLink', {'next': 'texHyperrefText'})
  call vimtex#syntax#core#new_arg('texHyperrefText')

  syntax match texCmdHyperref "\\url\>"
        \ skipwhite nextgroup=texUrlArg
  call vimtex#syntax#core#new_arg('texUrlArg', {'contains': '@NoSpell'})

  if a:cfg.conceal
    syntax match texCmdHyperref '\\href\>'
          \ skipwhite nextgroup=texHrefArgLinkC
          \ conceal
    call vimtex#syntax#core#new_arg('texHrefArgLinkC', {
          \ 'opts': 'contained conceal',
          \ 'next': 'texHrefArgTextC',
          \ 'contains': 'texHrefLinkGroup,@NoSpell',
          \})
    call vimtex#syntax#core#new_arg('texHrefLinkGroup', {
          \ 'matchgroup': 'matchgroup=NONE',
          \ 'opts': 'contained conceal',
          \ 'contains': 'texHrefLinkGroup',
          \})
    call vimtex#syntax#core#new_arg('texHrefArgTextC', {
          \ 'opts': 'contained concealends',
          \})

    syntax match texCmdHyperref '\\texorpdfstring\>'
          \ skipwhite nextgroup=texTOPSArgTex
          \ conceal
    call vimtex#syntax#core#new_arg('texTOPSArgTex', {
          \ 'opts': 'contained concealends transparent',
          \ 'next': 'texTOPSArgPdf',
          \})
    call vimtex#syntax#core#new_arg('texTOPSArgPdf', {
          \ 'opts': 'contained conceal',
          \ 'contains': '',
          \})
  else
    syntax match texCmdHyperref '\\href\>'
          \ skipwhite nextgroup=texHrefArgLink
    call vimtex#syntax#core#new_arg('texHrefArgLink', {
          \ 'next': 'texHrefArgText',
          \ 'contains': 'texHrefLinkGroup,@NoSpell',
          \})
    call vimtex#syntax#core#new_arg('texHrefLinkGroup', {
          \ 'matchgroup': 'matchgroup=NONE',
          \ 'contains': 'texHrefLinkGroup',
          \})
    call vimtex#syntax#core#new_arg('texHrefArgText')

    syntax match texCmdHyperref '\\texorpdfstring\>'
          \ skipwhite nextgroup=texTOPSArgTex
    call vimtex#syntax#core#new_arg('texTOPSArgTex', {
          \ 'opts': 'contained transparent',
          \ 'next': 'texTOPSArgPdf',
          \})
    call vimtex#syntax#core#new_arg('texTOPSArgPdf', {
          \ 'contains': '',
          \})
  endif

  highlight def link texCmdHyperref   texCmd
  highlight def link texHyperrefLink  texOpt
  highlight def link texHyperrefText  texArg
  highlight def link texHrefArgLink   texOpt
  highlight def link texHrefArgLinkC  texHrefArgLink
  highlight def link texHrefArgText   texArg
  highlight def link texHrefArgTextC  texHrefArgText
  highlight def link texHrefLinkGroup texHrefArgLink
  highlight def link texUrlArg        texOpt
  highlight def link texTOPSArgPdf    texOpt
endfunction

" }}}1
