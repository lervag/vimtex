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
        \ skipwhite skipempty nextgroup=texLstsetArg,texLstsetGroup
  syntax region texLstsetGroup matchgroup=texDelim
        \ start="{" skip="\\\\\|\\}" end="}"
        \ contained
        \ contains=texComment,texLength,texOptSep,texOptEqual

  " Match unspecified lstlisting environment
  syntax match texLstEnvBgn "\\begin{lstlisting}"
        \ nextgroup=texLstOpt skipwhite skipnl contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texLstOpt')
  syntax region texLstRegion
        \ start="\\begin{lstlisting}"
        \ end="\\end{lstlisting}"
        \ keepend
        \ contains=texLstEnvBgn,texCmdEnv

  " Add nested syntax support for desired languages
  for l:nested in b:vimtex_syntax.listings
    let l:cluster = vimtex#syntax#nested#include(l:nested)
    if empty(l:cluster) | continue | endif

    let l:groupname = 'texLstRegion' . toupper(l:nested[0]) . l:nested[1:]

    execute 'syntax match texLstsetArg'
          \ '"\c{\_[^}]*language=' . l:nested . '\%(\s*,\|}\)"'
          \ 'skipwhite skipempty nextgroup=' . l:groupname
          \ 'transparent'
          \ 'contains=texLstsetGroup'

    execute 'syntax region' l:groupname
          \ 'start="\\begin{lstlisting}"'
          \ 'end="\\end{lstlisting}"'
          \ 'keepend contained'
          \ 'contains=texLstEnvBgn,texCmdEnv,@' . l:cluster

    execute 'syntax region' l:groupname
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
