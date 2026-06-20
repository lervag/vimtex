" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#fixme#authors() abort " {{{1
  " Return the registered fixme author prefixes as a dictionary:
  "
  "   { 'cmd': [<command prefixes>], 'env': [<environment prefixes>] }
  "
  " The base/anonymous author uses the command prefix "fx" and the environment
  " prefix "anfx". Additional authors are registered in the preamble with
  " \FXRegisterAuthor{<cmdPrefix>}{<envPrefix>}{<initials>}, which creates the
  " commands \<cmdPrefix>note, \<cmdPrefix>warning, ... and the environments
  " <envPrefix>note, <envPrefix>warning, ... (see the fixme package manual).
  let l:base = #{ cmd: ['fx'], env: ['anfx'] }
  if !exists('b:vimtex') | return l:base | endif

  let l:cmd = copy(l:base.cmd)
  let l:env = copy(l:base.env)
  for l:line in vimtex#parser#tex#parse_preamble(b:vimtex.tex, {})
    let l:m = matchlist(l:line,
          \ '\\FXRegisterAuthor\s*{\([^}]*\)}\s*{\([^}]*\)}')
    if empty(l:m) | continue | endif
    if !empty(l:m[1]) | call add(l:cmd, l:m[1]) | endif
    if !empty(l:m[2]) | call add(l:env, l:m[2]) | endif
  endfor

  return #{
        \ cmd: vimtex#util#uniq_unsorted(l:cmd),
        \ env: vimtex#util#uniq_unsorted(l:env),
        \}
endfunction

" }}}1
