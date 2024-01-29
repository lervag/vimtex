" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#biblatex#load(cfg) abort " {{{1
  syntax match texCmdBib nextgroup=texFilesArg "\\addbibresource\>"

  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\bibentry\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\Cite\>\*\?"
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
  call vimtex#syntax#core#new_opt('texRefOpts', {'next': 'texRefOpts,texRefArgs'})

  highlight def link texRefArgs texRefArg
  highlight def link texRefOpts texRefOpt

  if !g:vimtex_syntax_conceal.cites | return | endif

  let l:re_concealed_cites = '\v\\%(' . join([
        \ '%([Tt]ext|[Ss]mart|[Aa]uto)cite[s]?',
        \ '(foot)?cite[tp]?',
        \ '[Aa]utocite[s]?',
        \ '[Cc]ite%(title|author|year%(par)?|date)[s]?',
        \ '[Pp]arencite[s]?',
        \ '[Ppf]?[Nn]otecite',
        \ '[Ss]upercite[s]?',
        \ 'Cite',
        \ 'cite%(num|text|url|field|list|name)',
        \ 'citeal[tp]',
        \ 'foot%(full)?cite%(text)?',
        \ 'footcite%(s|texts)',
        \ 'fullcite[s]?',
        \ ], '|') . ')>\*?'

  if g:vimtex_syntax_conceal_cites.type ==# 'brackets'
    execute 'syntax match texCmdRefConcealed'
          \ '"' . l:re_concealed_cites . '"'
          \ 'conceal skipwhite nextgroup=texRefConcealedOpt1,texRefConcealedArg'
  elseif !empty(g:vimtex_syntax_conceal_cites.icon)
    execute 'syntax match texCmdRefConcealed'
          \ '"' . l:re_concealed_cites . '%(\[[^]]*\]){,2}\{[^}]*\}"'
          \ 'conceal cchar=' . g:vimtex_syntax_conceal_cites.icon
  endif
endfunction

" }}}1
