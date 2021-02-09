" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#markdown#load(cfg) abort " {{{1
  call vimtex#syntax#nested#include('markdown')
  call vimtex#syntax#core#new_region_env('texMarkdownZone', 'markdown',
        \ {'contains': 'texCmd,@vimtex_nested_markdown'})

  syntax match texCmdInput "\\markdownInput\>" nextgroup=texFileArg skipwhite skipnl
endfunction

" }}}1
