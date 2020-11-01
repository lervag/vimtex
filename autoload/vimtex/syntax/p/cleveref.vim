" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#cleveref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'cleveref') | return | endif
  let b:vimtex_syntax.cleveref = 1

  syntax match texCmd nextgroup=texArgCRef skipwhite skipnl
        \ "\\\%(\%(label\)\?c\%(page\)\?\|C\)ref\>"

  " \crefrange, \cpagerefrange (these commands expect two arguments)
  syntax match texCmd nextgroup=texArgCRefRange skipwhite skipnl
        \ "\\c\(page\)\?refrange\>"

  " \label[xxx]{asd}
  syntax match texCmd nextgroup=texOptCRef,texArgRef skipwhite skipnl "\\label\>"

  call vimtex#syntax#core#new_cmd_arg('texArgCRef', '', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_arg('texArgCRefRange', 'texArgCRef', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_opt('texOptCRef', 'texArgRef', '', 'oneline')

  highlight link texArgCRef      texArgRef
  highlight link texArgCRefRange texArgRef
  highlight link texOptCRef      texOpt
endfunction

" }}}1
