" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#listings#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'listings') | return | endif
  let b:vimtex_syntax.listings = s:get_nested_languages()

  " First some general support
  syntax match texCmd "\\lstinputlisting\>"
        \ nextgroup=texOptFile,texArgFile skipwhite skipnl
  syntax match texRegion "\\lstinline\s*\(\[.\{-}\]\)\={.\{-}}"

  " Set all listings environments to listings
  syntax cluster texFoldGroup add=texRegionListings
  call vimtex#syntax#core#new_region_env('texRegionListings', 'lstlisting')

  " Next add nested syntax support for desired languages
  for l:nested in b:vimtex_syntax.listings
    let l:cluster = vimtex#syntax#nested#include(l:nested)
    if empty(l:cluster) | continue | endif

    let l:group_main = 'texRegionListings' . toupper(l:nested[0]) . l:nested[1:]
    let l:group_lstset = l:group_main . 'Lstset'
    let l:group_contained = l:group_main . 'Contained'
    execute 'syntax cluster texFoldGroup add=' . l:group_main
    execute 'syntax cluster texFoldGroup add=' . l:group_lstset

    execute 'syntax region' l:group_main
          \ 'start="\c\\begin{lstlisting}\s*'
          \ . '\[\_[^\]]\{-}language=' . l:nested . '\%(\s*,\_[^\]]\{-}\)\?\]"'
          \ 'end="\\end{lstlisting}"'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texCmdEnv,@' . l:cluster

    execute 'syntax match' l:group_lstset
          \ '"\c\\lstset{.*language=' . l:nested . '\%(\s*,\|}\)"'
          \ 'transparent'
          \ 'contains=texCmd,texGroup'
          \ 'skipwhite skipempty'
          \ 'nextgroup=' . l:group_contained

    execute 'syntax region' l:group_contained
          \ 'start="\\begin{lstlisting}"'
          \ 'end="\\end{lstlisting}"'
          \ 'keepend'
          \ 'transparent'
          \ 'containedin=' . l:group_lstset
          \ 'contains=texCmd,texCmdEnv,@' . l:cluster
  endfor

  highlight link texRegionListings texRegion
endfunction

" }}}1

function! s:get_nested_languages() abort " {{{1
  return map(
        \ filter(getline(1, '$'), "v:val =~# 'language='"),
        \ {_, x -> matchstr(x, 'language=\zs\w\+')})
endfunction

" }}}1
