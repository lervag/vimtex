" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! latex#mappings#init(initialized)
  call latex#util#set_default('g:latex_mappings_enabled', 1)
  if !g:latex_mappings_enabled | return | endif

  nmap <silent><buffer> <localleader>li <plug>(vl-info)
  nmap <silent><buffer> <localleader>lh <plug>(vl-help)
  nmap <silent><buffer> <localleader>lR <plug>(vl-reinit)

  nmap <silent><buffer> dse  <plug>(vl-delete-env)
  nmap <silent><buffer> dsc  <plug>(vl-delete-cmd)
  nmap <silent><buffer> cse  <plug>(vl-change-env)
  nmap <silent><buffer> csc  <plug>(vl-change-cmd)
  nmap <silent><buffer> tse  <plug>(vl-toggle-star)
  nmap <silent><buffer> tsd  <plug>(vl-toggle-delim)
  nmap <silent><buffer> <F7> <plug>(vl-create-cmd)
  imap <silent><buffer> <F7> <plug>(vl-create-cmd)
  imap <silent><buffer> ]]   <plug>(vl-close-env)

  if g:latex_latexmk_enabled
    nmap <silent><buffer> <localleader>ll <plug>(vl-compile-toggle)
    nmap <silent><buffer> <localleader>lo <plug>(vl-compile-output)
    nmap <silent><buffer> <localleader>lk <plug>(vl-stop)
    nmap <silent><buffer> <localleader>lK <plug>(vl-stop-all)
    nmap <silent><buffer> <localleader>le <plug>(vl-errors)
    nmap <silent><buffer> <localleader>lc <plug>(vl-clean)
    nmap <silent><buffer> <localleader>lC <plug>(vl-clean-full)
    nmap <silent><buffer> <localleader>lg <plug>(vl-status)
    nmap <silent><buffer> <localleader>lG <plug>(vl-status-all)
  endif

  if g:latex_motion_enabled
    nmap <silent><buffer> %  <plug>(vl-%)
    xmap <silent><buffer> %  <plug>(vl-%)
    omap <silent><buffer> %  <plug>(vl-%)
    nmap <silent><buffer> ]] <plug>(vl-]])
    nmap <silent><buffer> ][ <plug>(vl-][)
    nmap <silent><buffer> [] <plug>(vl-[])
    nmap <silent><buffer> [[ <plug>(vl-[[)
    xmap <silent><buffer> ]] <plug>(vl-]])
    xmap <silent><buffer> ][ <plug>(vl-][)
    xmap <silent><buffer> [] <plug>(vl-[])
    xmap <silent><buffer> [[ <plug>(vl-[[)
    omap <silent><buffer> ]] <plug>(vl-]])
    omap <silent><buffer> ][ <plug>(vl-][)
    omap <silent><buffer> [] <plug>(vl-[])
    omap <silent><buffer> [[ <plug>(vl-[[)
    xmap <silent><buffer> ie <plug>(vl-ie)
    xmap <silent><buffer> ae <plug>(vl-ae)
    omap <silent><buffer> ie <plug>(vl-ie)
    omap <silent><buffer> ae <plug>(vl-ae)
    xmap <silent><buffer> i$ <plug>(vl-i$)
    xmap <silent><buffer> a$ <plug>(vl-a$)
    omap <silent><buffer> i$ <plug>(vl-i$)
    omap <silent><buffer> a$ <plug>(vl-a$)
    xmap <silent><buffer> id <plug>(vl-id)
    xmap <silent><buffer> ad <plug>(vl-ad)
    omap <silent><buffer> id <plug>(vl-id)
    omap <silent><buffer> ad <plug>(vl-ad)
  endif

  if g:latex_toc_enabled
    nmap <silent><buffer> <localleader>lt <plug>(vl-toc-open)
    nmap <silent><buffer> <localleader>lT <plug>(vl-toc-toggle)
  endif

  if g:latex_view_enabled
    nmap <silent><buffer> <localleader>lv <plug>(vl-view)
    if has_key(g:latex#data[b:latex.id], 'rsearch')
      nmap <silent><buffer> <localleader>lr <plug>(vl-reverse-search)
    endif
  endif
endfunction

" vim: fdm=marker sw=2
