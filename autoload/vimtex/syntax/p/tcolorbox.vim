" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#tcolorbox#load(cfg) abort " {{{1
  call s:parse_constructs()

  " Match texTCBZone environment "boundaries"
  syntax match texCmdTCBEnv contained '\\begin{\w\+}'
        \ nextgroup=texTCBEnvArg skipwhite
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_arg('texTCBEnvArg', {'contains': ''})

  " Add listing support for detected environments
  for l:env in b:vimtex.syntax.tcolorbox.listing_envs
    call vimtex#syntax#core#new_env({
          \ 'name': l:env,
          \ 'region': 'texTCBZone',
          \ 'contains': 'texCmdEnv,texCmdTCBEnv',
          \})
  endfor

  highlight def link texTCBZone texZone
  highlight def link texTCBEnvArg texArg
endfunction

" }}}1

function! s:parse_constructs() abort " {{{1
  if has_key(b:vimtex.syntax, 'tcolorbox') | return | endif

  let l:re = '\c\\\%(declare\|new\)tcblisting'

  let b:vimtex.syntax.tcolorbox = {}
  let b:vimtex.syntax.tcolorbox.listing_envs = map(filter(
        \   vimtex#parser#tex(b:vimtex.tex, {'detailed': 0}),
        \   { _, x -> x =~? l:re }),
        \ {_, x -> matchstr(x, l:re . '\s*{\zs[a-zA-Z-]\+\ze}')})
endfunction

" }}}1
