" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1)
  finish
endif

if !exists('g:tex_flavor')
  call vimtex#log#warning(['g:tex_flavor not specified',
        \ 'Please read :help vimtex-tex-flavor!'])
endif
