" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#natbib#load(cfg) abort " {{{1
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\Cite[pt]\?\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[cC]iteal[tp]\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\cite\%(num\|text\|url\)\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Cc]ite\%(title\|author\|year\%(par\)\?\|date\)\>\*\?"

  if !g:vimtex_syntax_conceal.cites | return | endif

  if g:vimtex_syntax_conceal_cites.type ==# 'brackets'
    syntax match texCmdRefConcealed "\v\\Cite[t]?>\*?" conceal
          \ skipwhite nextgroup=texRefConcealedOpt1,texRefConcealedArg
    syntax match texCmdRefConcealed "\v\\Citep>\*?" conceal
          \ skipwhite nextgroup=texRefConcealedPOpt1,texRefConcealedPArg
  elseif !empty(g:vimtex_syntax_conceal_cites.icon)
    execute 'syntax match texCmdRefConcealed'
          \ '"\v\\Cite[tp]?>\*?%(\[[^]]*\]){,2}\{[^}]*\}"'
          \ 'conceal cchar=' . g:vimtex_syntax_conceal_cites.icon
  endif
endfunction

" }}}1
