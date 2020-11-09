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

  " Match minted language names
  syntax region texMintedName matchgroup=texDelim start="{" end="}" contained
  syntax region texMintedNameOpt matchgroup=texDelim start="\[" end="\]" contained

  " Match boundaries of minted environments
  syntax match texMintedBounds '\\end{minted}'
        \ contained
        \ contains=texCmdEnv
  syntax match texMintedBounds '\\begin{minted}'
        \ contained
        \ contains=texCmdEnv
        \ nextgroup=texMintedBoundsOpts,texMintedName
  syntax region texMintedBoundsOpts matchgroup=texDelim
        \ start="\[" end="\]"
        \ contained
        \ nextgroup=texMintedName

  " Match starred custom minted environments with options
  syntax match texMintedStarred "\\begin{\w\+\*}"
        \ contained
        \ contains=texCmdEnv
        \ nextgroup=texMintedStarredOpts
  syntax region texMintedStarredOpts matchgroup=texDelim
        \ start='{'
        \ end='}'
        \ contained
        \ containedin=texMintedStarred

  " Match \newminted type macros
  syntax match texCmd '\\newmint\%(ed\|inline\)\?\>' skipwhite skipnl nextgroup=texMintedName,texMintedNameOpt

  " Match "unknown" environments
  syntax region texMintedRegion
        \ start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{\w\+}"
        \ end="\\end{minted}"
        \ keepend
        \ contains=texMintedBounds.*

  " Match "unknown" commands
  syntax match texMintedArg "{\w\+}"
        \ contained
        \ contains=texMintedName
        \ nextgroup=texMintedRegionArg
  syntax region texMintedRegionArg matchgroup=texDelim
        \ start='\z([|+/]\)'
        \ end='\z1'
        \ contained
  syntax region texMintedRegionArg matchgroup=texDelim
        \ start='{'
        \ end='}'
        \ contained

  " Next add nested syntax support for desired languages
  for [l:nested, l:config] in items(b:vimtex.syntax.minted)
    let l:cluster = vimtex#syntax#nested#include(l:nested)

    let l:name = toupper(l:nested[0]) . l:nested[1:]
    let l:group_main = 'texMintedRegion' . l:name
    let l:group_arg = 'texMintedArg' . l:name
    let l:group_arg_zone = 'texMintedRegion' . l:name . 'Inline'

    if empty(l:cluster)
      let l:transparent = ''
      let l:contains_env = ''
      let l:contains_macro = ''
      execute 'highlight link' l:group_main 'texMintedRegion'
      execute 'highlight link' l:group_arg_zone 'texMintedRegion'
    else
      let l:transparent = 'transparent'
      let l:contains_env = ',@' . l:cluster
      let l:contains_macro = 'contains=@' . l:cluster
    endif

    " Match minted environment
    execute 'syntax region' l:group_main
          \ 'start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{' . l:nested . '}"'
          \ 'end="\\end{minted}"'
          \ 'keepend'
          \ l:transparent
          \ 'contains=texMintedBounds.*' . l:contains_env

    " Match custom environment names
    for l:env in get(l:config, 'environments', [])
      execute 'syntax region' l:group_main
            \ 'start="\\begin{\z(' . l:env . '\*\?\)}"'
            \ 'end="\\end{\z1}"'
            \ 'keepend'
            \ l:transparent
            \ 'contains=texMintedStarred,texCmdEnv' . l:contains_env
    endfor

    " Match minted macros
    " - \mint[]{lang}|...|
    " - \mint[]{lang}{...}
    " - \mintinline[]{lang}|...|
    " - \mintinline[]{lang}{...}
    execute 'syntax match' l:group_arg '''{' . l:nested . '}'''
          \ 'contained'
          \ 'contains=texMintedName'
          \ 'nextgroup=' . l:group_arg_zone
    execute 'syntax region' l:group_arg_zone
          \ 'matchgroup=texDelim'
          \ 'start=''\z([|+/]\)'''
          \ 'end=''\z1'''
          \ 'contained'
          \ l:contains_macro
    execute 'syntax region' l:group_arg_zone
          \ 'matchgroup=texDelim'
          \ 'start=''{'''
          \ 'end=''}'''
          \ 'contained'
          \ l:contains_macro

    " Match minted custom macros
    for l:cmd in sort(get(l:config, 'commands', []))
      execute printf('syntax match texCmd ''\\%s'' nextgroup=%s',
            \ l:cmd, l:group_arg_zone)
    endfor
  endfor

  " Main matcher for the minted statements/commands
  " - Note: This comes last to allow the nextgroup pattern
  syntax match texCmd '\\mint\(inline\)\?' nextgroup=texArgOptMinted,texMintedArg.*
  syntax region texArgOptMinted matchgroup=texDelim
        \ start='\[' end='\]'
        \ contained
        \ nextgroup=texMintedArg.*

  highlight link texMintedRegion texRegion
  highlight link texMintedRegionArg texRegion
  highlight link texMintedName texOpt
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
    let l:matches = matchlist(l:line,
          \ '\\newminted\%(\s*\[\([^\]]*\)\]\)\?\s*{\([a-zA-Z-]\+\)}')
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
    let l:matches = matchlist(l:line,
          \ '\\newmint\(inline\)\?\%(\s*\[\([^\]]*\)\]\)\?\s*{\([a-zA-Z-]\+\)}')
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
  " Avoid dashes in langnames
  let l:lang = substitute(a:lang, '-', '', 'g')

  if !has_key(self.data, l:lang)
    let self.data[l:lang] = {
          \ 'environments' : [],
          \ 'commands' : [],
          \}
  endif

  let self.cur = self.data[l:lang]
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
