" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#biblatex#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'biblatex') | return | endif
  let b:vimtex_syntax.biblatex = 1

  syntax match texCmd nextgroup=texArgFiles "\\addbibresource\>"

  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\bibentry\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\cite[pt]\?\*\?\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\citeal[tp]\*\?\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\cite\%(num\|text\|url\)\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\[Cc]ite\%(title\|author\|year\%(par\)\?\|date\)\*\?\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\[Pp]arencite\*\?\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\foot\%(full\)\?cite\%(text\)\?\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\fullcite\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\[Tt]extcite\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\[Ss]martcite\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\supercite\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\[Aa]utocite\*\?\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\[Ppf]\?[Nn]otecite\>"
  syntax match texCmd nextgroup=texOptRef,texArgRef skipwhite skipnl "\\\%(text\|block\)cquote\*\?\>"

  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\[Cc]ites\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\[Pp]arencites\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\footcite\%(s\|texts\)\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\[Tt]extcites\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\[Ss]martcites\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\supercites\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\[Aa]utocites\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\[pPfFsStTaA]\?[Vv]olcites\?\>"
  syntax match texCmd nextgroup=texOptRefs,texArgRefs skipwhite skipnl "\\cite\%(field\|list\|name\)>"
  call vimtex#syntax#core#new_cmd_arg('texArgRefs', 'texOptRefs,texArgRefs', 'texComment,@NoSpell')
  call vimtex#syntax#core#new_cmd_opt('texOptRefs', 'texOptRef,texArgRef')
endfunction

" }}}1
