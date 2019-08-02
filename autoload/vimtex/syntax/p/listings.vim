" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#listings#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'listings') | return | endif
  let b:vimtex_syntax.listings = s:get_nested_languages()

  " First some general support
  syntax match texInputFile
        \ "\\lstinputlisting\s*\(\[.*\]\)\={.\{-}}"
        \ contains=texStatement,texInputCurlies,texInputFileOpt
  syntax match texZone "\\lstinline\s*\(\[.*\]\)\={.\{-}}"

  " Set all listings environments to listings
  syntax cluster texFoldGroup add=texZoneListings
  syntax region texZoneListings
        \ start="\\begin{lstlisting}\(\_s*\[\_[^\]]\{-}\]\)\?"rs=s
        \ end="\\end{lstlisting}\|%stopzone\>"re=e
        \ keepend
        \ contains=texBeginEnd

  " Next add nested syntax support for desired languages
  for l:nested in b:vimtex_syntax.listings
    let l:cluster = vimtex#syntax#misc#include(l:nested)
    if empty(l:cluster) | continue | endif

    let l:group_main = 'texZoneListings' . toupper(l:nested[0]) . l:nested[1:]
    let l:group_lstset = l:group_main . 'Lstset'
    let l:group_contained = l:group_main . 'Contained'
    execute 'syntax cluster texFoldGroup add=' . l:group_main
    execute 'syntax cluster texFoldGroup add=' . l:group_lstset

    execute 'syntax region' l:group_main
          \ 'start="\c\\begin{lstlisting}\s*'
          \ . '\[\_[^\]]\{-}language=' . l:nested . '\%(\s*,\_[^\]]\{-}\)\?\]"rs=s'
          \ 'end="\\end{lstlisting}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texBeginEnd,@' . l:cluster

    execute 'syntax match' l:group_lstset
          \ '"\c\\lstset{.*language=' . l:nested . '\%(\s*,\|}\)"'
          \ 'transparent'
          \ 'contains=texStatement,texMatcher'
          \ 'skipwhite skipempty'
          \ 'nextgroup=' . l:group_contained

    execute 'syntax region' l:group_contained
          \ 'start="\\begin{lstlisting}"rs=s'
          \ 'end="\\end{lstlisting}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'containedin=' . l:group_lstset
          \ 'contains=texStatement,texBeginEnd,@' . l:cluster
  endfor

  highlight link texZoneListings texZone
endfunction

" }}}1

function! s:get_nested_languages() abort " {{{1
  return map(
        \ filter(getline(1, '$'), "v:val =~# 'language='"),
        \ 'matchstr(v:val, ''language=\zs\w\+'')')
endfunction

" }}}1
