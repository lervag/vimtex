" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#mappings#init(initialized)
  call vimtex#util#set_default('g:vimtex_mappings_enabled', 1)
  if !g:vimtex_mappings_enabled | return | endif

  nmap <silent><buffer> <localleader>li <plug>(vimtex-info)

  nmap <silent><buffer> dse  <plug>(vimtex-delete-env)
  nmap <silent><buffer> dsc  <plug>(vimtex-delete-cmd)
  nmap <silent><buffer> cse  <plug>(vimtex-change-env)
  nmap <silent><buffer> csc  <plug>(vimtex-change-cmd)
  nmap <silent><buffer> tse  <plug>(vimtex-toggle-star)
  nmap <silent><buffer> tsd  <plug>(vimtex-toggle-delim)
  nmap <silent><buffer> <F7> <plug>(vimtex-create-cmd)
  imap <silent><buffer> <F7> <plug>(vimtex-create-cmd)
  imap <silent><buffer> ]]   <plug>(vimtex-close-env)

  if g:vimtex_latexmk_enabled
    nmap <silent><buffer> <localleader>ll <plug>(vimtex-compile-toggle)
    nmap <silent><buffer> <localleader>lo <plug>(vimtex-compile-output)
    nmap <silent><buffer> <localleader>lk <plug>(vimtex-stop)
    nmap <silent><buffer> <localleader>lK <plug>(vimtex-stop-all)
    nmap <silent><buffer> <localleader>le <plug>(vimtex-errors)
    nmap <silent><buffer> <localleader>lc <plug>(vimtex-clean)
    nmap <silent><buffer> <localleader>lC <plug>(vimtex-clean-full)
    nmap <silent><buffer> <localleader>lg <plug>(vimtex-status)
    nmap <silent><buffer> <localleader>lG <plug>(vimtex-status-all)
  endif

  if g:vimtex_motion_enabled
    nmap <silent><buffer> %  <plug>(vimtex-%)
    xmap <silent><buffer> %  <plug>(vimtex-%)
    omap <silent><buffer> %  <plug>(vimtex-%)
    nmap <silent><buffer> ]] <plug>(vimtex-]])
    nmap <silent><buffer> ][ <plug>(vimtex-][)
    nmap <silent><buffer> [] <plug>(vimtex-[])
    nmap <silent><buffer> [[ <plug>(vimtex-[[)
    xmap <silent><buffer> ]] <plug>(vimtex-]])
    xmap <silent><buffer> ][ <plug>(vimtex-][)
    xmap <silent><buffer> [] <plug>(vimtex-[])
    xmap <silent><buffer> [[ <plug>(vimtex-[[)
    omap <silent><buffer> ]] <plug>(vimtex-]])
    omap <silent><buffer> ][ <plug>(vimtex-][)
    omap <silent><buffer> [] <plug>(vimtex-[])
    omap <silent><buffer> [[ <plug>(vimtex-[[)
    xmap <silent><buffer> ie <plug>(vimtex-ie)
    xmap <silent><buffer> ae <plug>(vimtex-ae)
    omap <silent><buffer> ie <plug>(vimtex-ie)
    omap <silent><buffer> ae <plug>(vimtex-ae)
    xmap <silent><buffer> i$ <plug>(vimtex-i$)
    xmap <silent><buffer> a$ <plug>(vimtex-a$)
    omap <silent><buffer> i$ <plug>(vimtex-i$)
    omap <silent><buffer> a$ <plug>(vimtex-a$)
    xmap <silent><buffer> id <plug>(vimtex-id)
    xmap <silent><buffer> ad <plug>(vimtex-ad)
    omap <silent><buffer> id <plug>(vimtex-id)
    omap <silent><buffer> ad <plug>(vimtex-ad)
  endif

  if g:vimtex_toc_enabled
    nmap <silent><buffer> <localleader>lt <plug>(vimtex-toc-open)
    nmap <silent><buffer> <localleader>lT <plug>(vimtex-toc-toggle)
  endif

  if g:vimtex_labels_enabled
    nmap <silent><buffer> <localleader>ly <plug>(vimtex-labels-open)
    nmap <silent><buffer> <localleader>lY <plug>(vimtex-labels-toggle)
  endif

  if g:vimtex_view_enabled
    nmap <silent><buffer> <localleader>lv <plug>(vimtex-view)
    if has_key(g:vimtex#data[b:vimtex.id], 'rsearch')
      nmap <silent><buffer> <localleader>lr <plug>(vimtex-reverse-search)
    endif
  endif
endfunction

" vim: fdm=marker sw=2
