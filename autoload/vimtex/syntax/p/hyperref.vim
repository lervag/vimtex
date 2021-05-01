" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#hyperref#load(cfg) abort " {{{1
  syntax match texCmdHyperref '\\autoref\>' nextgroup=texRefOpt,texRefArg
  syntax match texCmdHyperref '\\hyperref\>' nextgroup=texRefOpt,texRefArg

  syntax match texCmdHyperref "\\url\>" nextgroup=texUrlArg skipwhite
  syntax region texUrlArg matchgroup=texDelim
        \ contained contains=@NoSpell
        \ start="\z([^\ta-zA-Z]\)" end="\z1"
  call vimtex#syntax#core#new_arg('texUrlArg', {'contains': '@NoSpell'})

  if a:cfg.conceal
    syntax match texCmdHyperref '\\href\>' nextgroup=texHrefArgLink skipwhite
          \ conceal
    call vimtex#syntax#core#new_arg('texHrefArgLink', {
          \ 'opts': 'contained conceal',
          \ 'next': 'texHrefArgTextC',
          \ 'contains': 'texHrefLinkGroup,@NoSpell',
          \})
    call vimtex#syntax#core#new_arg('texHrefArgTextC', {
          \ 'opts': 'contained concealends',
          \})

    " To match possibly nested groups of {}s in an url string
    syntax region texHrefLinkGroup start="{" end="}" conceal
          \ contained contains=texHrefLinkGroup
  else
    syntax match texCmdHyperref '\\href\>' nextgroup=texHrefArgLink skipwhite
    call vimtex#syntax#core#new_arg('texHrefArgLink', {
          \ 'next': 'texHrefArgText',
          \ 'contains': 'texHrefLinkGroup,@NoSpell',
          \})
    call vimtex#syntax#core#new_arg('texHrefArgText')

    " To match possibly nested groups of {}s in an url string
    syntax region texHrefLinkGroup start="{" end="}"
          \ contained contains=texHrefLinkGroup
  endif

  highlight def link texCmdHyperref   texCmd
  highlight def link texHrefArgLink   texOpt
  highlight def link texHrefArgTextC  texArg
  highlight def link texHrefLinkGroup texHrefArgLink
  highlight def link texUrlArg        texOpt
endfunction

" }}}1
