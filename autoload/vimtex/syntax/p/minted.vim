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

  " Match \newminted type macros
  syntax match texCmdNewmint '\\newmint\%(ed\|inline\)\?\>'
        \ skipwhite skipnl nextgroup=texNewmintOpt,texNewmintArgX
  syntax region texNewmintOpt contained matchgroup=texDelim
        \ start="\[" end="\]"
        \ skipwhite skipnl nextgroup=texNewmintArgY
  syntax region texNewmintArgX contained matchgroup=texDelim
        \ start="{" end="}"
        \ skipwhite skipnl nextgroup=texNewmintArgOpts
  syntax region texNewmintArgY contained matchgroup=texDelim
        \ start="{" end="}"
        \ skipwhite skipnl nextgroup=texNewmintArgOpts
  syntax region texNewmintArgOpts contained matchgroup=texDelim
        \ start="{" end="}"

  " Match minted environment boundaries
  syntax match texMintedEnvBgn contained '\\begin{minted}'
        \ contains=texCmdEnv
        \ skipwhite skipnl nextgroup=texMintedEnvOpt,texMintedEnvArg
  syntax region texMintedEnvOpt contained matchgroup=texDelim
        \ start="\[" end="\]"
        \ skipwhite skipnl nextgroup=texMintedEnvArg
  syntax region texMintedEnvArg contained matchgroup=texDelim
        \ start="{" end="}"

  " Match custom starred minted environments and their options
  syntax match texMintedEnvBgn "\\begin{\w\+\*}"
        \ contained
        \ contains=texCmdEnv
        \ nextgroup=texMintedEnvOptStarred
  syntax region texMintedEnvOptStarred contained matchgroup=texDelim
        \ start='{' end='}'

  " Match "unknown" environments
  syntax region texMintedRegion
        \ start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{\w\+}"
        \ end="\\end{minted}"
        \ keepend
        \ contains=texCmdEnv,texMintedEnvBgn

  " Match "unknown" commands
  syntax region texMintedArg contained matchgroup=texDelim
        \ start='{' end='}'
        \ skipwhite skipnl nextgroup=texMintedRegionArg
  syntax region texMintedRegionArg contained matchgroup=texDelim
        \ start='\z([|+/]\)' end='\z1'
  syntax region texMintedRegionArg contained matchgroup=texDelim
        \ start='{' end='}'

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
          \ 'contains=texCmdEnv,texMintedEnvBgn' . l:contains_env

    " Match custom environment names
    for l:env in get(l:config, 'environments', [])
      execute 'syntax region' l:group_main
            \ 'start="\\begin{\z(' . l:env . '\*\?\)}"'
            \ 'end="\\end{\z1}"'
            \ 'keepend'
            \ l:transparent
            \ 'contains=texCmdEnv,texMintedEnvBgn' . l:contains_env
    endfor

    " Match minted macros
    " - \mint[]{lang}|...|
    " - \mint[]{lang}{...}
    " - \mintinline[]{lang}|...|
    " - \mintinline[]{lang}{...}
    execute 'syntax match' l:group_arg '''{' . l:nested . '}'''
          \ 'contained'
          \ 'contains=texMintedArg'
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
  syntax match texCmdMinted '\\mint\(inline\)\?'
        \ skipwhite skipnl nextgroup=texMintedOpt,texMintedArg.*
  syntax region texMintedOpt contained matchgroup=texDelim
        \ start='\[' end='\]'
        \ skipwhite skipnl nextgroup=texMintedArg.*

  highlight def link texCmdMinted           texCmd
  highlight def link texMintedOpt           texOpt
  highlight def link texMintedArg           texSymbol

  highlight def link texMintedRegion        texRegion
  highlight def link texMintedRegionArg     texRegion
  highlight def link texMintedEnvOpt        texOpt
  highlight def link texMintedEnvOptStarred texOpt
  highlight def link texMintedEnvArg        texSymbol

  highlight def link texCmdNewmint      texCmd
  highlight def link texNewmintOpt      texSymbol
  highlight def link texNewmintArgX     texSymbol
  highlight def link texNewmintArgY     texComment
  highlight def link texNewmintArgOpts  texOpt
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
