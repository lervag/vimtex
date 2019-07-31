" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#hyperref#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'hyperref') | return | endif
  let b:vimtex_syntax.hyperref = 1

  syntax match texStatement '\\url\ze[^\ta-zA-Z]' nextgroup=texUrlVerb
  syntax region texUrlVerb matchgroup=Delimiter
        \ start='\z([^\ta-zA-Z]\)' end='\z1' contained

  syntax match texStatement '\\url\ze\s*{' nextgroup=texUrl
  syntax region texUrl     matchgroup=Delimiter start='{' end='}' contained

  syntax match texStatement '\\href' nextgroup=texHref
  syntax region texHref matchgroup=Delimiter start='{' end='}' contained
        \ nextgroup=texMatcher

  syntax match texStatement '\\hyperref' nextgroup=texHyperref
  syntax region texHyperref matchgroup=Delimiter start='\[' end='\]' contained

  highlight link texUrl          Function
  highlight link texUrlVerb      texUrl
  highlight link texHref         texUrl
  highlight link texHyperref     texRefZone
endfunction

" }}}1
