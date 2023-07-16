" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#breqn#load(cfg) abort " {{{1
  for l:env in ['dmath', 'dseries', 'dgroup', 'darray']
    call vimtex#syntax#core#new_env(#{
          \ name: l:env,
          \ starred: v:true,
          \ math: v:true
          \})
  endfor
endfunction

" }}}1
