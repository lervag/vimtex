" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! latex#mappings#init(initialized)
  call latex#util#set_default('g:latex_mappings_enabled', 1)
  if !g:latex_mappings_enabled | return | endif

  nmap <buffer> <localleader>li <plug>VimLatexInfo
  nmap <buffer> <localleader>lh <plug>VimLatexHelp
  nmap <buffer> <localleader>lR <plug>VimLatexReinit

  " Change
  nnoremap <buffer> dse  <plug>VimLatexDeleteEnv
  nnoremap <buffer> cse  <plug>VimLatexDeleteCmd
  nnoremap <buffer> dsc  <plug>VimLatexChangeEnv
  nnoremap <buffer> csc  <plug>VimLatexChangeCmd
  nnoremap <buffer> tse  <plug>VimLatexToggleEnvStar
  nnoremap <buffer> tsd  <plug>VimLatexToggleDelim
  nnoremap <buffer> <F7> <plug>VimLatexChangeToCmd
  inoremap <buffer> <F7> <plug>VimLatexChangeToCmd
  inoremap <buffer> ]]   <plug>VimLatexCloseEnv

  if g:latex_latexmk_enabled
    nmap <buffer> <localleader>ll <plug>VimLatexCompileToggle
    nmap <buffer> <localleader>lo <plug>VimLatexCompileOutput
    nmap <buffer> <localleader>lk <plug>VimLatexStop
    nmap <buffer> <localleader>lK <plug>VimLatexStopAll
    nmap <buffer> <localleader>le <plug>VimLatexErrors
    nmap <buffer> <localleader>lc <plug>VimLatexClean
    nmap <buffer> <localleader>lC <plug>VimLatexCleanFull
    nmap <buffer> <localleader>lg <plug>VimLatexStatus
    nmap <buffer> <localleader>lG <plug>VimLatexStatusAll
  endif

  if g:latex_motion_enabled
    nmap <buffer> %  <plug>VimLatex%
    xmap <buffer> %  <plug>VimLatex%
    omap <buffer> %  <plug>VimLatex%
    nmap <buffer> ]] <plug>VimLatex]]
    nmap <buffer> ][ <plug>VimLatex][
    nmap <buffer> [] <plug>VimLatex[]
    nmap <buffer> [[ <plug>VimLatex[[
    xmap <buffer> ]] <plug>VimLatex]]
    xmap <buffer> ][ <plug>VimLatex][
    xmap <buffer> [] <plug>VimLatex[]
    xmap <buffer> [[ <plug>VimLatex[[
    omap <buffer> ]] <plug>VimLatex]]
    omap <buffer> ][ <plug>VimLatex][
    omap <buffer> [] <plug>VimLatex[]
    omap <buffer> [[ <plug>VimLatex[[
    xmap <buffer> ie <plug>VimLatexie
    xmap <buffer> ae <plug>VimLatexae
    omap <buffer> ie <plug>VimLatexie
    omap <buffer> ae <plug>VimLatexae
    xmap <buffer> i$ <plug>VimLatexi$
    xmap <buffer> a$ <plug>VimLatexa$
    omap <buffer> i$ <plug>VimLatexi$
    omap <buffer> a$ <plug>VimLatexa$
    xmap <buffer> id <plug>VimLatexid
    xmap <buffer> ad <plug>VimLatexad
    omap <buffer> id <plug>VimLatexid
    omap <buffer> ad <plug>VimLatexad
  endif

  if g:latex_toc_enabled
    nmap <buffer> <localleader>lt <plug>VimLatexTocOpen
    nmap <buffer> <localleader>lT <plug>VimLatexTocToggle
  endif

  if g:latex_view_enabled
    nmap <buffer> <localleader>lv <plug>VimLatexView
    if has_key(g:latex#data[b:latex.id], 'rsearch')
      nmap <buffer> <localleader>lr <plug>VimLatexRSearch
    endif
  endif
endfunction

" vim: fdm=marker sw=2
