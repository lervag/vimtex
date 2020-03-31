" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pdfpages#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pdfpages') | return | endif
  let b:vimtex_syntax.pdfpages = 1

  syntax match texInputFile /\\includepdf\>/
        \ contains=texStatement
        \ nextgroup=texInputFileOpt,texInputFileArg
  syntax region texInputFileOpt
        \ matchgroup=Delimiter
        \ start="\[" end="\]"
        \ contained
        \ contains=texComment,@NoSpell
        \ nextgroup=texInputFileArg
  syntax region texInputFileArg
        \ matchgroup=texInputCurlies
        \ start="{" end="}"
        \ contained
        \ contains=texComment

  highlight default link texInputFileArg texInputFile
endfunction

" }}}1
