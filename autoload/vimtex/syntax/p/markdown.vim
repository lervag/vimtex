" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#markdown#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'markdown') | return | endif
  let b:vimtex_syntax.markdown = 1

  call vimtex#syntax#nested#include('markdown')
  call vimtex#syntax#core#new_region_env(
        \ 'texMarkdownRegion', 'markdown', 'texCmd,@vimtex_nested_markdown')

  syntax match texCmdInput "\\markdownInput\>" nextgroup=texFileArg skipwhite skipnl
endfunction

" }}}1
