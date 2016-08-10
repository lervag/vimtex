" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1)
  finish
endif

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

function! s:map(mode, lhs, rhs, ...)
  if !hasmapto(a:rhs, a:mode)
        \ && (a:0 > 0 || maparg(a:lhs, a:mode) ==# '')
    silent execute a:mode . 'map <silent><buffer>' a:lhs a:rhs
  endif
endfunction

if get(g:, 'vimtex_toc_enabled', 1)
  if exists('g:vimtex_data[get(b:, "vimtex_id")].root')
    command! -buffer VimtexTocOpen   call vimtex#toc#open()
    command! -buffer VimtexTocToggle call vimtex#toc#toggle()
    nnoremap <buffer> <plug>(vimtex-toc-open)   :call vimtex#toc#open()<cr>
    nnoremap <buffer> <plug>(vimtex-toc-toggle) :call vimtex#toc#toggle()<cr>
    call s:map('n', '<localleader>lt', '<plug>(vimtex-toc-open)')
    call s:map('n', '<localleader>lT', '<plug>(vimtex-toc-toggle)')
  else
    let bib_warning = 'In order to use the ToC the .bib file has to be opened from within a .tex document!'
    command! -buffer VimtexTocOpen
          \ call vimtex#echo#warning(bib_warning)
    command! -buffer VimtexTocToggle
          \ call vimtex#echo#warning(bib_warning)
    nnoremap <buffer> <plug>(vimtex-toc-open)
          \ :call vimtex#echo#warning(bib_warning)<CR>
    nnoremap <buffer> <plug>(vimtex-toc-toggle)
          \ :call vimtex#echo#warning(bib_warning)<CR>
    call s:map('n', '<localleader>lt', '<plug>(vimtex-toc-open)')
    call s:map('n', '<localleader>lT', '<plug>(vimtex-toc-toggle)')
    unlet bib_warning
  endif

endif

" vim: fdm=marker sw=2
