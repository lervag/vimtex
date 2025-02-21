" VimTeX - LaTeX plugin for Vim
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

if !(!get(g:, 'vimtex_version_check', 1)
      \ || has('nvim-0.10')
      \ || has('patch-9.1.16'))
  echoerr 'Error: VimTeX does not support your version of Vim'
  echom 'Please update to Vim 9.1.16 or neovim 0.10 or later!'
  echom 'For more info, please see :h vimtex_version_check'
  finish
endif

call vimtex#init()

" Check if user has tree-sitter enabled and give a warning if that is the case.
" This is useful, since a lot of users are not aware of the clash between
" VimTeX's syntax highlighting and Tree-sitters syntax highlighting.
if has('nvim-0.5')
      \ && g:vimtex_syntax_enabled
      \ && !g:vimtex_syntax_conceal_disable
  call timer_start(1000, function('vimtex#nvim#check_treesitter', [bufnr()]))
endif
