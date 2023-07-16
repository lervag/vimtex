" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#ieeetrantools#load(cfg) abort " {{{1
  call vimtex#syntax#core#new_arg('texMathEnvIEEEArg')
  call vimtex#syntax#core#new_opt('texMathEnvIEEEOpt',
        \ {'next': 'texMathEnvIEEEArg'})
  for l:env in ['IEEEeqnarray', 'IEEEeqnarrayboxm']
    call vimtex#syntax#core#new_env({
          \ 'name': l:env,
          \ 'starred': v:true,
          \ 'math': v:true,
          \ 'math_nextgroup': 'texMathEnvIEEEOpt,texMathEnvIEEEArg',
          \})
  endfor

  highlight def link texMathEnvIEEEArg texArg
  highlight def link texMathEnvIEEEOpt texOpt
endfunction

" }}}1
