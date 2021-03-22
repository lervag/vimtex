" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#biblatex#load(cfg) abort " {{{1
  syntax match texCmdBib nextgroup=texFilesArg "\\addbibresource\>"

  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\bibentry\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\cite[pt]\?\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\citeal[tp]\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\cite\%(num\|text\|url\)\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Cc]ite\%(title\|author\|year\%(par\)\?\|date\)\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Pp]arencite\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\foot\%(full\)\?cite\%(text\)\?\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\fullcite\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Tt]extcite\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Ss]martcite\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\supercite\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Aa]utocite\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Ppf]\?[Nn]otecite\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\\%(text\|block\)cquote\>\*\?"

  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\[Cc]ites\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\[Pp]arencites\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\footcite\%(s\|texts\)\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\[Tt]extcites\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\[Ss]martcites\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\supercites\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\[Aa]utocites\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\[pPfFsStTaA]\?[Vv]olcites\?\>"
  syntax match texCmdRef nextgroup=texRefOpts,texRefArgs skipwhite skipnl "\\cite\%(field\|list\|name\)>"
  call vimtex#syntax#core#new_arg('texRefArgs', {'next': 'texRefOpts,texRefArgs', 'contains': 'texComment,@NoSpell'})
  call vimtex#syntax#core#new_opt('texRefOpts', {'next': 'texRefOpt,texRefArg'})

  if g:vimtex_syntax_conceal.citations
        \ && !empty(g:vimtex_syntax_conceal_citesign)
    execute 'syntax match texCmdRefConcealed'
          \ '"\v\\%(cite[tp]?\*?|%([Tt]ext|[Ss]mart|[Aa]uto)cite)'
          \   . '%(\[[^]]*\]){,2}\{[^}]*\}"'
          \ 'conceal cchar=' . g:vimtex_syntax_conceal_citesign
  endif
endfunction

" }}}1
