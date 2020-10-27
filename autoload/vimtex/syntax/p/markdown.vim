" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#markdown#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'markdown') | return | endif
  let b:vimtex_syntax.markdown = 1

  call vimtex#syntax#misc#include('markdown')

  " Don't quite know why this is necessary, but it is
  syntax match texCmdEnv "\\\%(begin\|end\)\>\ze{markdown}" nextgroup=texEnvName

  syntax region texRegionMarkdown
        \ start="\\begin{markdown}"
        \ end="\\end{markdown}"
        \ keepend transparent
        \ contains=texCmdEnv,texEnvName,@vimtex_nested_markdown

  syntax match texCmd "\\markdownInput\>" nextgroup=texFileArg
endfunction

" }}}1
