" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#minted#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'minted') | return | endif
  let b:vimtex_syntax.minted = 1

  " First set all minted environments to listings
  syntax cluster texFoldGroup add=texZoneMinted
  syntax region texZoneMinted
        \ start="\\begin{minted}\_[^}]\{-}{\w\+}"rs=s
        \ end="\\end{minted}"re=e
        \ keepend
        \ contains=texMinted

  " Highlight "unknown" statements
  syntax region texArgMintedUnknown matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained
        \ nextgroup=texArgZoneMintedUnknown
  syntax region texArgZoneMintedUnknown matchgroup=Delimiter
        \ start='\z([|+/]\)'
        \ end='\z1'
        \ contained
  syntax region texArgZoneMintedUnknown matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained

  " Next add nested syntax support for desired languages
  for [l:nested, l:config] in items(g:vimtex_syntax_minted)
    let l:cluster = vimtex#syntax#misc#include(l:nested)
    if empty(l:cluster) | continue | endif

    let l:name = 'Minted' . toupper(l:nested[0]) . l:nested[1:]
    let l:group_main = 'texZone' . l:name
    let l:group_arg = 'texArg' . l:name
    let l:group_arg_zone = 'texArgZone' . l:name
    execute 'syntax cluster texFoldGroup add=' . l:group_main

    " Add statement variants
    " - \mint[]{lang}|...|
    " - \mint[]{lang}{...}
    " - \mintinline[]{lang}|...|
    " - \mintinline[]{lang}{...}
    execute 'syntax match' l:group_arg '''{' . l:nested . '}'''
          \ 'contained'
          \ 'nextgroup=' . l:group_arg_zone
    execute 'syntax region' l:group_arg_zone
          \ 'matchgroup=Delimiter'
          \ 'start=''\z([|+/]\)'''
          \ 'end=''\z1'''
          \ 'contained'
          \ 'contains=@' . l:cluster
    execute 'syntax region' l:group_arg_zone
          \ 'matchgroup=Delimiter'
          \ 'start=''{'''
          \ 'end=''}'''
          \ 'contained'
          \ 'contains=@' . l:cluster

    " Add main minted environment
    execute 'syntax region' l:group_main
          \ 'start="\\begin{minted}\_[^}]\{-}{' . l:nested . '}"rs=s'
          \ 'end="\\end{minted}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texMinted,@' . l:cluster

    " Support for custom environment names
    for l:env in get(l:config, 'environments', [])
      execute 'syntax region' l:group_main
            \ 'start="\\begin{' . l:env . '}"rs=s'
            \ 'end="\\end{' . l:env . '}"re=e'
            \ 'keepend'
            \ 'transparent'
            \ 'contains=texBeginEnd,@' . l:cluster

      " Match starred environments with options
      execute 'syntax region' l:group_main
            \ 'start="\\begin{' . l:env . '\*}\s*{\_.\{-}}"rs=s'
            \ 'end="\\end{' . l:env . '\*}"re=e'
            \ 'keepend'
            \ 'transparent'
            \ 'contains=texMintedStarred,texBeginEnd,@' . l:cluster
      execute 'syntax match texMintedStarred'
            \ '"\\begin{' . l:env . '\*}\s*{\_.\{-}}"'
            \ 'contains=texBeginEnd,texDelimiter'
    endfor

    " Support for custom commands
    for l:cmd in sort(get(l:config, 'commands', []))
      execute 'syntax match texStatement'
            \ '''\\' . l:cmd . ''''
            \ 'nextgroup=' . l:group_arg_zone
    endfor
  endfor

  " Main matcher for the minted statements/commands (must come last to allow
  " nextgroup patterns)
  syntax match texStatement '\\mint\(inline\)\?' nextgroup=texArgOptMinted,texArgMinted.*
  syntax region texArgOptMinted matchgroup=Delimiter
        \ start='\['
        \ end='\]'
        \ contained
        \ nextgroup=texArgMinted.*

  syntax match texMinted '\\begin{minted}\_[^}]\{-}{\w\+}'
        \ contains=texBeginEnd,texMintedName
  syntax match texMinted '\\end{minted}'
        \ contains=texBeginEnd
  syntax match texMintedName '{\w\+}' contained

  highlight link texMinted texZone
  highlight link texArgZoneMintedUnknown texZone
  highlight link texMintedName texBeginEndName
endfunction

" }}}1
