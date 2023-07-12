" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#moreverb#load(cfg) abort " {{{1
  for l:env in ['verbatimtab', 'verbatimwrite', 'boxedverbatim']
    call vimtex#syntax#core#new_env({
          \ 'name': l:env,
          \ 'region': 'texVerbZone'
          \})
  endfor
endfunction

" }}}1
