" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#minted#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'minted') | return | endif
  let b:vimtex_syntax.minted = 1

  " Parse minted macros in the current project
  call s:parse_minted_constructs()

  " First set all minted environments to listings
  syntax cluster texFoldGroup add=texZoneMinted
  syntax region texZoneMinted
        \ start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{\w\+}"rs=s
        \ end="\\end{minted}"re=e
        \ keepend
        \ contains=texMintedBounds

  " Highlight "unknown" statements
  syntax region texArgMinted matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained
        \ nextgroup=texArgZoneMinted
  syntax region texArgZoneMinted matchgroup=Delimiter
        \ start='\z([|+/]\)'
        \ end='\z1'
        \ contained
  syntax region texArgZoneMinted matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained

  " Next add nested syntax support for desired languages
  for [l:nested, l:config] in items(b:vimtex.syntax.minted)
    let l:cluster = vimtex#syntax#misc#include(l:nested)
    if empty(l:cluster) | continue | endif

    let l:name = 'Minted' . toupper(l:nested[0]) . l:nested[1:]
    let l:group_main = 'texZone' . l:name
    let l:group_arg = 'texArg' . l:name
    let l:group_arg_zone = 'texArgZone' . l:name
    execute 'syntax cluster texFoldGroup add=' . l:group_main

    " Add minted environment
    execute 'syntax region' l:group_main
          \ 'start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{' . l:nested . '}"rs=s'
          \ 'end="\\end{minted}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texMintedBounds,@' . l:cluster

    " Add macros
    " - \mint[]{lang}|...|
    " - \mint[]{lang}{...}
    " - \mintinline[]{lang}|...|
    " - \mintinline[]{lang}{...}
    execute 'syntax match' l:group_arg '''{' . l:nested . '}'''
          \ 'contained'
          \ 'contains=texMintedName'
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
  " for the nextgroup patterns)
  syntax match texStatement '\\mint\(inline\)\?' nextgroup=texArgOptMinted,texArgMinted.*
  syntax region texArgOptMinted matchgroup=Delimiter
        \ start='\['
        \ end='\]'
        \ contained
        \ nextgroup=texArgMinted.*

  " Matcher for newminted type macros
  syntax match texStatement '\\newmint\%(ed\|inline\)\?' nextgroup=texMintedName,texMintedNameOpt
  syntax region texArgOptMinted matchgroup=Delimiter
        \ start='\['
        \ end='\]'
        \ contained
        \ nextgroup=texArgMinted.*

  " Apply proper highlighting of environment boundaries
  syntax match texMintedBounds '\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\s*{\w\+}'
        \ extend
        \ contains=texMintedName,texBeginEnd
  syntax match texMintedBounds '\\end{minted}'
        \ contains=texBeginEnd

  syntax region texMintedName matchgroup=Delimiter start="{" end="}" contained
  syntax region texMintedNameOpt matchgroup=Delimiter start="\[" end="\]" contained

  highlight link texArgZoneMinted texZone
  highlight link texMintedName texInputFileOpt
  highlight link texMintedNameOpt texMintedName
endfunction

" }}}1

function! s:parse_minted_constructs() abort " {{{1
  if has_key(b:vimtex.syntax, 'minted') | return | endif

  let l:db = deepcopy(s:db)
  let b:vimtex.syntax.minted = l:db.data

  let l:in_multi = 0
  for l:line in vimtex#parser#tex(b:vimtex.tex, {'detailed': 0})
    " Multiline minted environments
    if l:in_multi
      let l:lang = matchstr(l:line, '\]\s*{\zs\w\+\ze}')
      if !empty(l:lang)
        call l:db.register(l:lang)
        let l:in_multi = 0
      endif
      continue
    endif
    if l:line =~# '\\begin{minted}\s*\[[^\]]*$'
      let l:in_multi = 1
      continue
    endif

    " Single line minted environments
    let l:lang = matchstr(l:line, '\\begin{minted}\%(\s*\[\[^\]]*\]\)\?\s*{\zs\w\+\ze}')
    if !empty(l:lang)
      call l:db.register(l:lang)
      continue
    endif

    " Simple minted commands
    let l:lang = matchstr(l:line, '\\mint\%(\s*\[[^\]]*\]\)\?\s*{\zs\w\+\ze}')
    if !empty(l:lang)
      call l:db.register(l:lang)
      continue
    endif

    " Custom environments:
    " - \newminted{lang}{opts} -> langcode
    " - \newminted[envname]{lang}{opts} -> envname
    let l:matches = matchlist(l:line, '\\newminted\%(\s*\[\([^\]]*\)\]\)\?\s*{\(\w\+\)}')
    if !empty(l:matches)
      call l:db.register(l:matches[2])
      call l:db.add_environment(!empty(l:matches[1])
            \ ? l:matches[1]
            \ : l:matches[2] . 'code')
      continue
    endif

    " Custom macros:
    " - \newmint(inline){lang}{opts} -> \lang(inline)
    " - \newmint(inline)[macroname]{lang}{opts} -> \macroname
    let l:matches = matchlist(l:line, '\\newmint\(inline\)\?\%(\s*\[\([^\]]*\)\]\)\?\s*{\(\w\+\)}')
    if !empty(l:matches)
      call l:db.register(l:matches[3])
      call l:db.add_macro(!empty(l:matches[2])
            \ ? l:matches[2]
            \ : l:matches[3] . l:matches[1])
      continue
    endif
  endfor
endfunction

" }}}1


let s:db = {
      \ 'data' : {},
      \}

function! s:db.register(lang) abort dict " {{{1
  if !has_key(self.data, a:lang)
    let self.data[a:lang] = {
          \ 'environments' : [],
          \ 'commands' : [],
          \}
  endif

  let self.cur = self.data[a:lang]
endfunction

" }}}1
function! s:db.add_environment(envname) abort dict " {{{1
  if index(self.cur.environments, a:envname) < 0
    let self.cur.environments += [a:envname]
  endif
endfunction

" }}}1
function! s:db.add_macro(macroname) abort dict " {{{1
  if index(self.cur.commands, a:macroname) < 0
    let self.cur.commands += [a:macroname]
  endif
endfunction

" }}}1
