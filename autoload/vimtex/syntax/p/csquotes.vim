" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#csquotes#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'csquotes') | return | endif
  let b:vimtex_syntax.csquotes = 1

  syntax match texCmdQuote nextgroup=texQuoteArg skipwhite skipnl "\\\%(foreign\|hyphen\)textcquote\*\?\>"
  syntax match texCmdQuote nextgroup=texQuoteArg skipwhite skipnl "\\\%(foreign\|hyphen\)blockcquote\>"
  syntax match texCmdQuote nextgroup=texQuoteArg skipwhite skipnl "\\hybridblockcquote\>"
  call vimtex#syntax#core#new_cmd_arg('texQuoteArg', 'texRefOpt,texRefArg', '@texClusterTL', 'transparent')

  highlight def link texCmdQuote texCmd
endfunction

" }}}1
