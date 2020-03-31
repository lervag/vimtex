" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#markdown#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'markdown') | return | endif
  let b:vimtex_syntax.markdown = 1

  call vimtex#syntax#misc#add_to_section_clusters('texZoneMarkdown')
  call vimtex#syntax#misc#include('markdown')

  " Don't quite know why this is necessary, but it is
  syntax match texBeginEnd
        \ '\(\\begin\>\|\\end\>\)\ze{markdown}'
        \ nextgroup=texBeginEndName

  syntax region texZoneMarkdown
        \ start='\\begin{markdown}'rs=s
        \ end='\\end{markdown}'re=e
        \ keepend
        \ transparent
        \ contains=@texFoldGroup,@texDocGroup,@vimtex_nested_markdown

  " Input files
  syntax match texInputFile /\\markdownInput\>/
        \ contains=texStatement
        \ nextgroup=texInputFileArg
  syntax region texInputFileArg
        \ matchgroup=texInputCurlies
        \ start="{" end="}"
        \ contained
        \ contains=texComment

  highlight default link texInputFileArg texInputFile
endfunction

" }}}1
