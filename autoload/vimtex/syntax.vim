" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#init() abort " {{{1
  if !get(g:, 'vimtex_syntax_enabled', 1) | return | endif

  " The following ensures that syntax addons are not loaded until after the
  " filetype plugin has been sourced. See e.g. #1428 for more info.
  if exists('b:vimtex')
    call vimtex#syntax#load()
  else
    augroup vimtex_syntax
      autocmd!
      autocmd User VimtexEventInitPost call vimtex#syntax#load()
    augroup END
  endif
endfunction

" }}}1
function! vimtex#syntax#load() abort " {{{1
  if !exists('b:current_syntax')
    let b:current_syntax = 'tex'
  elseif b:current_syntax !=# 'tex'
    return
  endif

  " Set some better defaults
  syntax spell toplevel
  syntax sync maxlines=500

  " Initialize b:vimtex_syntax if necessary
  let b:vimtex_syntax = get(b:, 'vimtex_syntax', {})

  " Load some general syntax improvements
  call vimtex#syntax#load#general()

  "
  " Load syntax for documentclass
  "
  try
    call vimtex#syntax#p#{b:vimtex.documentclass}#load()
  catch /E117: Unknown function/
  endtry

  "
  " Load syntax for packages
  "
  for l:package in keys(b:vimtex.packages)
    try
      call vimtex#syntax#p#{l:package}#load()
    catch /E117: Unknown function/
    endtry
  endfor
endfunction

" }}}1
