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
  syntax region texMintArgUnknown matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained
        \ nextgroup=texMintZoneUnknown
  syntax region texMintZoneUnknown matchgroup=Delimiter
        \ start='\z([|+/]\)'
        \ end='\z1'
        \ contained
  syntax region texMintZoneUnknown matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained

  " Next add nested syntax support for desired languages
  for l:entry in get(g:, 'vimtex_syntax_minted', [])
    let l:lang = l:entry.lang
    let l:syntax = get(l:entry, 'syntax', l:lang)

    let l:cap_name = toupper(l:lang[0]) . l:lang[1:]
    let l:group_name = 'texZoneMinted' . l:cap_name
    execute 'syntax cluster texFoldGroup add=' . l:group_name

    unlet b:current_syntax
    execute 'syntax include @' . toupper(l:lang) 'syntax/' . l:syntax . '.vim'
    let b:current_syntax = 'tex'

    if has_key(l:entry, 'ignore')
      execute 'syntax cluster' toupper(l:lang)
            \ 'remove=' . join(l:entry.ignore, ',')
    endif

    " Add statement variants
    " - \mint[]{lang}|...|
    " - \mint[]{lang}{...}
    " - \mintinline[]{lang}|...|
    " - \mintinline[]{lang}{...}
    execute 'syntax match texMintArg' . l:cap_name  '''{' . l:lang . '}'''
          \ 'contained'
          \ 'nextgroup=texMintZone' . l:cap_name
    execute 'syntax region texMintZone' . l:cap_name
          \ 'matchgroup=Delimiter'
          \ 'start=''\z([|+/]\)'''
          \ 'end=''\z1'''
          \ 'contained'
          \ 'contains=@' . toupper(l:lang)
    execute 'syntax region texMintZone' . l:cap_name
          \ 'matchgroup=Delimiter'
          \ 'start=''{'''
          \ 'end=''}'''
          \ 'contained'
          \ 'contains=@' . toupper(l:lang)

    " Add main minted environment
    execute 'syntax region' l:group_name
          \ 'start="\\begin{minted}\_[^}]\{-}{' . l:lang . '}"rs=s'
          \ 'end="\\end{minted}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texMinted,@' . toupper(l:lang)

    " Support for custom environment names
    for l:env in get(l:entry, 'environments', [])
      execute 'syntax region' l:group_name
            \ 'start="\\begin{' . l:env . '}"rs=s'
            \ 'end="\\end{' . l:env . '}"re=e'
            \ 'keepend'
            \ 'transparent'
            \ 'contains=texBeginEnd,@' . toupper(l:lang)

      " Match starred environments with options
      execute 'syntax region' l:group_name
            \ 'start="\\begin{' . l:env . '\*}\s*{\_.\{-}}"rs=s'
            \ 'end="\\end{' . l:env . '\*}"re=e'
            \ 'keepend'
            \ 'transparent'
            \ 'contains=texMintedStarred,texBeginEnd,@' . toupper(l:lang)
      execute 'syntax match texMintedStarred'
            \ '"\\begin{' . l:env . '\*}\s*{\_.\{-}}"'
            \ 'contains=texBeginEnd,texDelimiter'
    endfor

    " Support for custom commands
    for l:cmd in sort(get(l:entry, 'commands', []))
      execute 'syntax match texStatement'
            \ '''\\' . l:cmd . ''''
            \ 'nextgroup=texMintZone' . l:cap_name
    endfor
  endfor

  " Main matcher for the minted statements/commands (must come last to allow
  " nextgroup patterns)
  syntax match texStatement '\\mint\(inline\)\?' nextgroup=texMintOptArg,texMintArg.*
  syntax region texMintOptArg matchgroup=Delimiter
        \ start='\['
        \ end='\]'
        \ contained
        \ nextgroup=texMintArg.*

  syntax match texMinted '\\begin{minted}\_[^}]\{-}{\w\+}'
        \ contains=texBeginEnd,texMintedName
  syntax match texMinted '\\end{minted}'
        \ contains=texBeginEnd
  syntax match texMintedName '{\w\+}' contained

  highlight link texMinted texZone
  highlight link texMintZoneUnknown texZone
  highlight link texMintedName texBeginEndName
endfunction

" }}}1
