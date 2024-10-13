" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#robust_externalize#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load("tikz")

  " Match environment boundaries
  syntax match texRobExtEnvBgn contained '\\begin{\%(RobExt\)\?CacheMeCode\|CacheMe}'
        \ nextgroup=texRobExtEnvOpt,texRobExtEnvArg skipwhite skipnl
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_opt('texRobExtEnvOpt', {'next': 'texRobExtEnvArg'})
  call vimtex#syntax#core#new_arg('texRobExtEnvArg', {'contains': 'texRobExtEnvArg'})

  " Match generic environments
  call vimtex#syntax#core#new_env({
        \ 'name': '\%(RobExt\)\?CacheMeCode\|CacheMe',
        \ 'region': 'texRobExtZone',
        \ 'contains': 'texCmdEnv,texRobExtEnvBgn',
        \})
  call vimtex#syntax#core#new_env({
        \ 'name': 'PlaceholderPathFromCode',
        \ 'region': 'texRobExtZone',
        \ 'contains': 'texCmdEnv,texRobExtEnvBgn',
        \})
  call vimtex#syntax#core#new_env({
        \ 'name': 'SetPlaceholderCode\*\?',
        \ 'region': 'texRobExtZone',
        \ 'contains': 'texCmdEnv,texRobExtEnvBgn',
        \})

  " Add nested syntax support for supported languages
  for [l:preset, l:target] in get(a:cfg, "presets", [])
    if empty(l:target)
      let l:name = 'Verb'
      let l:contains = 'contains=texCmdEnv,texRobExtEnvBgn'
      execute 'highlight def link' l:grp_env 'texRobExtZone'
    elseif l:target ==# "TOP"
      let l:name = 'LaTeX'
      let l:contains = 'contains=TOP,texRobExtZone'
    else
      let l:name = toupper(l:target[0]) . l:target[1:]
      let l:cluster = l:target[0] == "@"
            \ ? l:target
            \ : vimtex#syntax#nested#include(l:target)

      let l:contains = 'contains=texCmdEnv,texRobExtEnvBgn'
      let l:contains .= ',' . l:cluster
    endif

    let l:grp_env = 'texRobExtZone' . l:name

    " Match normal robext environments
    execute 'syntax region' l:grp_env
          \ 'start="\\begin{\z(\%(RobExt\)\?CacheMeCode\|CacheMe\)}\_s*{' . l:preset . '[ ,}]"'
          \ 'end="\\end{\z1}"'
          \ 'keepend'
          \ l:contains
  endfor

  " Specify default highlight groups
  highlight def link texRobExtEnvArg     texSymbol
  highlight def link texRobExtEnvArgOpt  texOpt
  highlight def link texRobExtEnvOpt     texOpt
  highlight def link texRobExtZone       texZone
endfunction

" }}}1
