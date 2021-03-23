" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#listings#load(cfg) abort " {{{1
  let b:vimtex_syntax.listings.nested = map(
        \ filter(getline(1, '$'), "v:val =~# 'language='"),
        \ {_, x -> matchstr(x, 'language=\zs\w\+')})

  " Match input file commands
  syntax match texCmd "\\lstinputlisting\>"
        \ nextgroup=texFileOpt,texFileArg skipwhite skipnl

  " Match \lstset
  syntax match texCmdLstset "\\lstset\>"
        \ nextgroup=texLstsetArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texLstsetArg', {
        \ 'contains': 'texCmdSize,texCmdStyle,@texClusterOpt'
        \})

  " Match unspecified lstlisting environment
  syntax match texLstEnvBgn "\\begin{lstlisting}"
        \ nextgroup=texLstOpt skipwhite skipnl contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texLstOpt')
  call vimtex#syntax#core#new_region_env('texLstZone', 'lstlisting', {
        \ 'contains': 'texLstEnvBgn',
        \})

  " Match generic "arguments" for \lstinline
  call vimtex#syntax#core#new_opt('texLstInlineOpt', {
        \ 'next': 'texLstZoneInline'
        \})
  call vimtex#syntax#core#new_arg('texLstZoneInline', {'contains': ''})
  call vimtex#syntax#core#new_arg('texLstZoneInline', {
        \ 'contains': '',
        \ 'matcher': 'start="\z([|+/]\)" end="\z1"',
        \})
  syntax match texLstDelim contained "\[\|\]"

  " Add nested syntax support for desired languages
  for l:nested in b:vimtex_syntax.listings.nested
    let l:cluster = vimtex#syntax#nested#include(l:nested)
    if empty(l:cluster) | continue | endif
    let l:name = toupper(l:nested[0]) . l:nested[1:]
    let l:grp = 'texLstZone' . l:name
    let l:grp_inline = 'texLstZoneInline' . l:name
    let l:cluster = '@' . l:cluster

    execute 'syntax match texLstsetArg'
          \ '"\c{\_[^}]*language=' . l:nested . '\%(\s*,\|}\)"'
          \ 'nextgroup=' . l:grp 'skipwhite skipnl'
          \ 'contains=texLstsetArg'

    call vimtex#syntax#core#new_region_env(l:grp, 'lstlisting', {
          \ 'contains': 'texLstEnvBgn,' . l:cluster,
          \ 'opts': 'contained',
          \})

    execute 'syntax region' l:grp
          \ 'start="\c\\begin{lstlisting}\s*'
          \ . '\[\_[^\]]\{-}language=' . l:nested . '\%(\s*,\_[^\]]\{-}\)\?\]"'
          \ 'end="\\end{lstlisting}"'
          \ 'keepend'
          \ 'contains=texCmdEnv,texLstEnvBgn,' . l:cluster

    " Allow inline \lstinline[language=...]{....} variants
    execute 'syntax region texLstInlineOpt'
          \ 'contained'
          \ 'start="\[language=' . l:nested . '"'
          \ 'skip="\\\\\|\\\]"'
          \ 'end="\]"'
          \ 'contains=@texClusterOpt,texLstDelim'
          \ 'nextgroup=' . l:grp_inline
          \ 'skipwhite skipnl keepend'
    call vimtex#syntax#core#new_arg(l:grp_inline, {'contains': l:cluster})
    call vimtex#syntax#core#new_arg(l:grp_inline, {
          \ 'contains': l:cluster,
          \ 'matcher': 'start="\z([|+/]\)" end="\z1"',
          \})
  endfor

  " Match inline listings
  syntax match texCmdVerb "\\lstinline\>"
        \ nextgroup=texLstInlineOpt,texLstZoneInline

  highlight def link texCmdLstset     texCmd
  highlight def link texLstDelim      texDelim
  highlight def link texLstInlineOpt  texOpt
  highlight def link texLstOpt        texOpt
  highlight def link texLstZone       texZone
  highlight def link texLstZoneInline texVerbZoneInline
  highlight def link texLstsetArg     texOpt
endfunction

" }}}1
