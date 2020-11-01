" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#markdown#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'markdown') | return | endif
  let b:vimtex_syntax.markdown = 1

  call vimtex#syntax#nested#include('markdown')

  " Don't quite know why this is necessary, but it is
  syntax match texCmdEnv "\\\%(begin\|end\)\>\ze{markdown}" nextgroup=texArgEnvName

  syntax region texRegionMarkdown
        \ start="\\begin{markdown}"
        \ end="\\end{markdown}"
        \ keepend transparent
        \ contains=texCmdEnv,texArgEnvName,@vimtex_nested_markdown

  syntax match texCmd "\\markdownInput\>" nextgroup=texArgFile
endfunction

" }}}1
