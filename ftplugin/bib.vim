" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1) || !get(g:, 'vimtex_toc_enabled', 1)
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

command! -buffer VimtexTocOpen   call vimtex#toc#open()
command! -buffer VimtexTocToggle call vimtex#toc#toggle()
nnoremap <buffer> <plug>(vimtex-toc-open)   :call vimtex#toc#open()<cr>
nnoremap <buffer> <plug>(vimtex-toc-toggle) :call vimtex#toc#toggle()<cr>
call s:map('n', '<localleader>lt', '<plug>(vimtex-toc-open)')
call s:map('n', '<localleader>lT', '<plug>(vimtex-toc-toggle)')

" vim: fdm=marker sw=2
