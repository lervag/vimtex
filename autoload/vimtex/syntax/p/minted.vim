" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#minted#load(cfg) abort " {{{1
  " Parse minted macros in the current project
  call s:parse_minted_constructs()

  " Match \newminted type macros
  syntax match texCmdNewmint '\\newmint\%(ed\|inline\)\?\>'
        \ skipwhite skipnl nextgroup=texNewmintOpt,texNewmintArgX
  call vimtex#syntax#core#new_opt('texNewmintOpt', {'next': 'texNewmintArgY'})
  call vimtex#syntax#core#new_arg('texNewmintArgX', {'contains': '', 'next': 'texNewmintArgOpts'})
  call vimtex#syntax#core#new_arg('texNewmintArgY', {'contains': '', 'next': 'texNewmintArgOpts'})
  call vimtex#syntax#core#new_arg('texNewmintArgOpts', {'contains': ''})

  " Match minted environment boundaries
  syntax match texMintedEnvBgn contained '\\begin{minted}'
        \ nextgroup=texMintedEnvOpt,texMintedEnvArg skipwhite
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texMintedEnvOpt', {'next': 'texMintedEnvArg'})
  call vimtex#syntax#core#new_arg('texMintedEnvArg', {'contains': ''})

  " Match starred custom minted environments and the option group
  syntax match texMintedEnvBgn contained "\\begin{\w\+\*}"
        \ nextgroup=texMintedEnvArgOpt skipwhite
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_arg('texMintedEnvArgOpt', {'contains': ''})

  " Match generic minted environment regions
  call vimtex#syntax#core#new_region_env('texMintedZone', 'minted', {
        \ 'contains': 'texCmdEnv,texMintedEnvBgn',
        \})

  " Match generic minted command regions
  call vimtex#syntax#core#new_arg('texMintedArg', {'contains': '', 'next': 'texMintedZoneInline'})
  call vimtex#syntax#core#new_arg('texMintedZoneInline', {'contains': ''})
  call vimtex#syntax#core#new_arg('texMintedZoneInline', {
        \ 'contains': '',
        \ 'matcher': 'start="\z([|+/]\)" end="\z1"',
        \})

  " Next add nested syntax support for desired languages
  for [l:nested, l:config] in items(b:vimtex.syntax.minted)
    let l:cluster = vimtex#syntax#nested#include(l:nested)

    let l:name = toupper(l:nested[0]) . l:nested[1:]
    let l:grp_env = 'texMintedZone' . l:name
    let l:grp_inline = 'texMintedZoneInline' . l:name
    let l:grp_inline_matcher = 'texMintedArg' . l:name

    let l:options = 'keepend'
    let l:contains = 'contains=texCmdEnv,texMintedEnvBgn'
    let l:contains_inline = ''

    if !empty(l:cluster)
      let l:contains .= ',@' . l:cluster
      let l:contains_inline = '@' . l:cluster
    else
      execute 'highlight def link' l:grp_env 'texMintedZone'
      execute 'highlight def link' l:grp_inline 'texMintedZoneInline'
    endif

    " Match normal minted environments
    execute 'syntax region' l:grp_env
          \ 'start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{' . l:nested . '}"'
          \ 'end="\\end{minted}"'
          \ l:options
          \ l:contains

    " Match custom minted environments
    for l:env in get(l:config, 'environments', [])
      execute 'syntax region' l:grp_env
            \ 'start="\\begin{\z(' . l:env . '\*\?\)}"'
            \ 'end="\\end{\z1}"'
            \ l:options
            \ l:contains
    endfor

    " Match normal inline minted command regions
    " Note: These are the language specific arguments for the commands
    "       \mint and \mintinline
    execute 'syntax match' l:grp_inline_matcher '"{' . l:nested . '}"'
          \ 'contained'
          \ 'contains=texMintedArg'
          \ 'nextgroup=' . l:grp_inline 'skipwhite skipnl'
    call vimtex#syntax#core#new_arg(l:grp_inline, {
          \ 'contains': l:contains_inline,
          \ 'matcher': 'start="\z([|+/]\)" end="\z1"',
          \})
    call vimtex#syntax#core#new_arg(l:grp_inline, {
          \ 'contains': l:contains_inline
          \})

    " Match custom inline minted commands
    for l:cmd in sort(get(l:config, 'commands', []))
      execute 'syntax match texCmdMinted'
            \ '"\\' . l:cmd . '\>"'
            \ 'nextgroup=' . l:grp_inline 'skipwhite skipnl'
    endfor
  endfor

  " Match inline minted commands
  " - \mint[]{lang}|...|
  " - \mint[]{lang}{...}
  " - \mintinline[]{lang}|...|
  " - \mintinline[]{lang}{...}
  " Note: This comes last to allow the nextgroup pattern
  syntax match texCmdMinted "\\mint\%(inline\)\?"
        \ nextgroup=texMintedOpt,texMintedArg.* skipwhite skipnl
  call vimtex#syntax#core#new_opt('texMintedOpt', {'next': 'texMintedArg.*'})

  " Specify default highlight groups
  highlight def link texCmdMinted        texCmd
  highlight def link texCmdNewmint       texCmd
  highlight def link texMintedArg        texSymbol
  highlight def link texMintedEnvArg     texSymbol
  highlight def link texMintedEnvArgOpt  texOpt
  highlight def link texMintedEnvOpt     texOpt
  highlight def link texMintedOpt        texOpt
  highlight def link texMintedZone       texZone
  highlight def link texMintedZoneInline texZone
  highlight def link texNewmintArgOpts   texOpt
  highlight def link texNewmintArgX      texSymbol
  highlight def link texNewmintArgY      texComment
  highlight def link texNewmintOpt       texSymbol
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
