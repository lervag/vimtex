" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#hyperref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'hyperref') | return | endif
  let b:vimtex_syntax.hyperref = 1

  syntax match texCmdHyperref '\\autoref\>' nextgroup=texRefOpt,texRefArg
  syntax match texCmdHyperref '\\hyperref\>' nextgroup=texRefOpt,texRefArg
  syntax match texCmdHyperref '\\href\>' nextgroup=texHrefArgLink skipwhite
  call vimtex#syntax#core#new_cmd_arg('texHrefArgLink', 'texHrefArgText', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_arg('texHrefArgText', '', '@texClusterMain')

  syntax match texCmdHyperref "\\url\>" nextgroup=texUrlArg skipwhite
  syntax region texUrlArg matchgroup=texDelim
        \ contained contains=@NoSpell,texComment
        \ start="\z([^\ta-zA-Z]\)" end="\z1"
  call vimtex#syntax#core#new_cmd_arg('texUrlArg', '', 'texComment,@NoSpell')


  highlight def link texCmdHyperref texCmd
  highlight def link texHrefArgLink texOpt
  highlight def link texUrlArg      texOpt
endfunction

" }}}1
