" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#cleveref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'cleveref') | return | endif
  let b:vimtex_syntax.cleveref = 1

  syntax match texCmdCRef nextgroup=texCRefArg skipwhite skipnl
        \ "\\\%(\%(label\)\?c\%(page\)\?\|C\)ref\>"

  " \crefrange, \cpagerefrange (these commands expect two arguments)
  syntax match texCmdCRef nextgroup=texCRefRangeArg skipwhite skipnl
        \ "\\c\(page\)\?refrange\>"

  " \label[xxx]{asd}
  syntax match texCmdCRef nextgroup=texCRefOpt,texRefArg skipwhite skipnl "\\label\>"

  call vimtex#syntax#core#new_arg('texCRefArg', {'contains': 'texComment,@NoSpell'})
  call vimtex#syntax#core#new_arg('texCRefRangeArg', {'next': 'texCRefArg', 'contains': 'texComment,@NoSpell'})
  call vimtex#syntax#core#new_opt('texCRefOpt', {'next': 'texRefArg', 'opts': 'oneline'})

  highlight def link texCRefArg      texRefArg
  highlight def link texCRefOpt      texOpt
  highlight def link texCRefRangeArg texRefArg
  highlight def link texCmdCRef      texCmd
endfunction

" }}}1
