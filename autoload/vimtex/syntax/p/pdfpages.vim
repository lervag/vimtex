" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pdfpages#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pdfpages') | return | endif
  let b:vimtex_syntax.pdfpages = 1

  syntax match texCmd "\\includepdf\>" nextgroup=texOptFile,texArgFile
endfunction

" }}}1
