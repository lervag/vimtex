" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

scriptencoding utf-8

function! vimtex#syntax#p#ieeetrantools#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_arg('texMathEnvIEEEArg')
  call vimtex#syntax#core#new_opt('texMathEnvIEEEOpt',
        \ {'next': 'texMathEnvIEEEArg'})
  for l:env in ['IEEEeqnarray', 'IEEEeqnarrayboxm']
    call vimtex#syntax#core#new_region_math(l:env, {
          \ 'next': 'texMathEnvIEEEOpt,texMathEnvIEEEArg',
          \})
  endfor

  highlight def link texMathEnvIEEEArg texArg
  highlight def link texMathEnvIEEEOpt texOpt
endfunction

" }}}1
