" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#robust_externalize#load(cfg) abort " {{{1
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
  for [l:preset, l:target] in [
        \ ['c', 'c'],
        \ ['bash', 'bash'],
        \ ['python', 'python'],
        \ ['my python', 'python'],
        \]
    let l:cluster = vimtex#syntax#nested#include(l:target)

    let l:name = toupper(l:target[0]) . l:target[1:]
    let l:grp_env = 'texRobExtZone' . l:name
    let l:options = 'keepend'
    let l:contains = 'contains=texCmdEnv,texRobExtEnvBgn'

    if empty(l:cluster)
      execute 'highlight def link' l:grp_env 'texRobExtZone'
    else
      let l:contains .= ',' . l:cluster
    endif

    " Match normal robext environments
    execute 'syntax region' l:grp_env
          \ 'start="\\begin{\z(\%(RobExt\)\?CacheMeCode\|CacheMe\)}\_s*{' . l:preset . '[ ,}]"'
          \ 'end="\\end{\z1}"'
          \ l:options
          \ l:contains
  endfor

  " Specify default highlight groups
  highlight def link texRobExtEnvArg     texSymbol
  highlight def link texRobExtEnvArgOpt  texOpt
  highlight def link texRobExtEnvOpt     texOpt
  highlight def link texRobExtZone       texZone
endfunction

" }}}1
