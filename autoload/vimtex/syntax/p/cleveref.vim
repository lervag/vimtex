" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#cleveref#load(cfg) abort " {{{1
  " \cref, \namecref, etc
  syntax match texCmdCRef nextgroup=texCRefArg skipwhite skipnl
        \ "\v\\%(%(label)?c%(page)?|C)ref>"
  syntax match texCmdCRef nextgroup=texCRefArg skipwhite skipnl
        \ "\v\\%(lc)?name[cC]refs?>"

  " \crefrange, \cpagerefrange (these commands expect two arguments)
  syntax match texCmdCRef nextgroup=texCRefRangeArg skipwhite skipnl
        \ "\\c\(page\)\?refrange\>"

  " \label[xxx]{asd}
  syntax match texCmdCRef nextgroup=texCRefOpt,texRefArg skipwhite skipnl
        \ "\\label\>"

  " \crefname
  syntax match texCmdCRName nextgroup=texCRNameArgType skipwhite skipnl
        \ "\\[cC]refname\>"

  " Argument and option groups
  call vimtex#syntax#core#new_arg('texCRefArg', {
        \ 'contains': 'texComment,@NoSpell',
        \})
  call vimtex#syntax#core#new_arg('texCRefRangeArg', {
        \ 'next': 'texCRefArg',
        \ 'contains': 'texComment,@NoSpell',
        \})
  call vimtex#syntax#core#new_opt('texCRefOpt', {
        \ 'next': 'texRefArg',
        \ 'opts': 'oneline',
        \})
  call vimtex#syntax#core#new_arg('texCRNameArgType', {
        \ 'next': 'texCRNameArgSingular',
        \ 'contains': 'texComment,@NoSpell',
        \})
  call vimtex#syntax#core#new_arg('texCRNameArgSingular', {
        \ 'next': 'texCRNameArgPlural',
        \ 'contains': 'texComment,@NoSpell'
        \})
  call vimtex#syntax#core#new_arg('texCRNameArgPlural', {
        \ 'contains': 'texComment,@NoSpell'
        \})

  highlight def link texCRefArg           texRefArg
  highlight def link texCRefOpt           texRefOpt
  highlight def link texCRefRangeArg      texRefArg
  highlight def link texCmdCRef           texCmdRef
  highlight def link texCmdCRName         texCmd
  highlight def link texCRNameArgType     texArgNew
  highlight def link texCRNameArgSingular texArg
  highlight def link texCRNameArgPlural   texCRNameArgSingular
endfunction

" }}}1
