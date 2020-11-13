" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#listings#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'listings') | return | endif

  let b:vimtex_syntax.listings = map(
        \ filter(getline(1, '$'), "v:val =~# 'language='"),
        \ {_, x -> matchstr(x, 'language=\zs\w\+')})

  " Match inline listings
  syntax match texCmdVerb "\\lstinline\>" nextgroup=texVerbRegionInline

  " Match input file commands
  syntax match texCmd "\\lstinputlisting\>"
        \ nextgroup=texFileOpt,texFileArg skipwhite skipnl

  " Match \lstset
  syntax match texCmdLstset "\\lstset\>"
        \ nextgroup=texLstsetArg,texLstsetGroup skipwhite skipnl
  call vimtex#syntax#core#new_arg('texLstsetGroup', {
        \ 'contains': 'texComment,texLength,texOptSep,texOptEqual'
        \})

  " Match unspecified lstlisting environment
  syntax match texLstEnvBgn "\\begin{lstlisting}"
        \ nextgroup=texLstOpt skipwhite skipnl contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texLstOpt')
  call vimtex#syntax#core#new_region_env('texLstRegion', 'lstlisting', {
        \ 'contains': 'texLstEnvBgn',
        \ 'transparent': 0,
        \})

  " Add nested syntax support for desired languages
  for l:nested in b:vimtex_syntax.listings
    let l:cluster = vimtex#syntax#nested#include(l:nested)
    if empty(l:cluster) | continue | endif

    let l:grp = 'texLstRegion' . toupper(l:nested[0]) . l:nested[1:]

    execute 'syntax match texLstsetArg'
          \ '"\c{\_[^}]*language=' . l:nested . '\%(\s*,\|}\)"'
          \ 'nextgroup=' . l:grp 'skipwhite skipnl'
          \ 'transparent'
          \ 'contains=texLstsetGroup'

    call vimtex#syntax#core#new_region_env(l:grp, 'lstlisting', {
          \ 'contains': 'texLstEnvBgn,@' . l:cluster,
          \ 'opts': 'contained',
          \})

    execute 'syntax region' l:grp
          \ 'start="\c\\begin{lstlisting}\s*'
          \ . '\[\_[^\]]\{-}language=' . l:nested . '\%(\s*,\_[^\]]\{-}\)\?\]"'
          \ 'end="\\end{lstlisting}"'
          \ 'keepend transparent'
          \ 'contains=texCmdEnv,texLstEnvBgn,@' . l:cluster
  endfor

  highlight def link texCmdLstset texCmd
  highlight def link texLstsetGroup texOpt
  highlight def link texLstRegion texRegion
  highlight def link texLstOpt texOpt
endfunction

" }}}1
