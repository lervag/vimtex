" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#natbib#load(cfg) abort " {{{1
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[cC]ite[pt]\?\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[cC]iteal[tp]\>\*\?"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\cite\%(num\|text\|url\)\>"
  syntax match texCmdRef nextgroup=texRefOpt,texRefArg skipwhite skipnl "\\[Cc]ite\%(title\|author\|year\%(par\)\?\|date\)\>\*\?"

  if g:vimtex_syntax_conceal.cites
    let s:re_concealed_cites = '\v\\%(' . join([
          \ '[cC]ite[tp]?',
          \ ], '|') . ')>\*?'
    call s:match_conceal_cites_{g:vimtex_syntax_conceal_cites.type}()
  endif
endfunction

" }}}1

function! s:match_conceal_cites_brackets() abort " {{{1
  execute 'syntax match texCmdRefConcealed'
        \ '"' . s:re_concealed_cites . '"'
        \ 'conceal skipwhite nextgroup=texRefConcealedOpt1,texRefConcealedArg'
endfunction

" }}}1
function! s:match_conceal_cites_icon() abort " {{{1
  if empty(g:vimtex_syntax_conceal_cites.icon) | return | endif

  execute 'syntax match texCmdRefConcealed'
        \ '"' . s:re_concealed_cites . '%(\[[^]]*\]){,2}\{[^}]*\}"'
        \ 'conceal cchar=' . g:vimtex_syntax_conceal_cites.icon
endfunction

" }}}1
