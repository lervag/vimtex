" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1) | finish | endif

autocmd BufNewFile,BufRead *.cls
	\ if getline(1) =~ '^%' |
	\  set filetype=tex |
	\ endif
