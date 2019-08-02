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
  syntax region texMintedName matchgroup=Delimiter start="{" end="}" contained
  syntax region texMintedNameOpt matchgroup=Delimiter start="\[" end="\]" contained

  " Match boundaries of minted environments
  syntax match texMintedBounds '\\end{minted}'
        \ contained
        \ contains=texBeginEnd
  syntax match texMintedBounds '\\begin{minted}'
        \ contained
        \ contains=texBeginEnd
        \ nextgroup=texMintedBoundsOpts,texMintedName
  syntax region texMintedBoundsOpts matchgroup=Delimiter
        \ start="\[" end="\]"
        \ contained
        \ nextgroup=texMintedName

  " Match starred custom minted environments with options
  syntax match texMintedStarred "\\begin{\w\+\*}"
        \ contained
        \ contains=texBeginEnd
        \ nextgroup=texMintedStarredOpts
  syntax region texMintedStarredOpts matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained
        \ containedin=texMintedStarred

  " Match \newminted type macros
  syntax match texStatement '\\newmint\%(ed\|inline\)\?' nextgroup=texMintedName,texMintedNameOpt

  " Match "unknown" environments
  call vimtex#syntax#misc#add_to_section_clusters('texZoneMinted')
  syntax region texZoneMinted
        \ start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{\w\+}"rs=s
        \ end="\\end{minted}"re=e
        \ keepend
        \ contains=texMintedBounds.*

  " Match "unknown" commands
  syntax match texArgMinted "{\w\+}"
        \ contained
        \ contains=texMintedName
        \ nextgroup=texZoneMintedCmd
  syntax region texZoneMintedCmd matchgroup=Delimiter
        \ start='\z([|+/]\)'
        \ end='\z1'
        \ contained
  syntax region texZoneMintedCmd matchgroup=Delimiter
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
    call vimtex#syntax#misc#add_to_section_clusters(l:group_main)

    " Match minted environment
    execute 'syntax region' l:group_main
          \ 'start="\\begin{minted}\%(\_s*\[\_[^\]]\{-}\]\)\?\_s*{' . l:nested . '}"rs=s'
          \ 'end="\\end{minted}"re=e'
          \ 'keepend'
          \ 'transparent'
          \ 'contains=texMintedBounds.*,@' . l:cluster

    " Match custom environment names
    for l:env in get(l:config, 'environments', [])
      execute 'syntax region' l:group_main
            \ 'start="\\begin{\z(' . l:env . '\*\?\)}"rs=s'
            \ 'end="\\end{\z1}"re=e'
            \ 'keepend'
            \ 'transparent'
            \ 'contains=texMintedStarred,texBeginEnd,@' . l:cluster
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

    " Match minted custom macros
    for l:cmd in sort(get(l:config, 'commands', []))
      execute printf('syntax match texStatement ''\\%s'' nextgroup=%s',
            \ l:cmd, l:group_arg_zone)
    endfor
  endfor

  " Main matcher for the minted statements/commands
  " - Note: This comes last to allow the nextgroup pattern
  syntax match texStatement '\\mint\(inline\)\?' nextgroup=texArgOptMinted,texArgMinted.*
  syntax region texArgOptMinted matchgroup=Delimiter
        \ start='\['
        \ end='\]'
        \ contained
        \ nextgroup=texArgMinted.*

  highlight link texZoneMinted texZone
  highlight link texZoneMintedCmd texZone
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
