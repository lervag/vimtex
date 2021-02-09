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
    call vimtex#syntax#core#new_region_env('texTCBZone', l:env, {
          \'contains': 'texCmdEnv,texCmdTCBEnv',
          \})
  endfor

  highlight def link texTCBZone texZone
  highlight def link texTCBEnvArg texArg
endfunction

" }}}1

function! s:parse_constructs() abort " {{{1
  if has_key(b:vimtex.syntax, 'tcolorbox') | return | endif

  let b:vimtex.syntax.tcolorbox = {'listing_envs': []}
  let b:vimtex.syntax.tcolorbox.listing_envs = map(filter(
        \   vimtex#parser#tex(b:vimtex.tex, {'detailed': 0}),
        \   'v:val =~# ''\\DeclareTCBListing'''),
        \ {_, x -> matchstr(x, '\\DeclareTCBListing\s*{\zs[a-zA-Z-]\+\ze}')})
endfunction

" }}}1
