" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#text_obj#targets#enabled() abort " {{{1
  return exists('g:loaded_targets')
        \ && (   (type(g:loaded_targets) == type(0)  && g:loaded_targets)
        \     || (type(g:loaded_targets) == type('') && !empty(g:loaded_targets)))
        \ && (   g:vimtex_text_obj_variant ==# 'auto'
        \     || g:vimtex_text_obj_variant ==# 'targets')
endfunction

" }}}1
function! vimtex#text_obj#targets#init() abort " {{{1
  let g:vimtex_text_obj_variant = 'targets'

  " Create intermediate mappings
  omap <expr> <plug>(vimtex-targets-i) targets#e('o', 'i', 'i')
  xmap <expr> <plug>(vimtex-targets-i) targets#e('x', 'i', 'i')
  omap <expr> <plug>(vimtex-targets-a) targets#e('o', 'a', 'a')
  xmap <expr> <plug>(vimtex-targets-a) targets#e('x', 'a', 'a')

  augroup vimtex_targets
    autocmd!
    autocmd User targets#sources         call s:init_sources()
    autocmd User targets#mappings#plugin call s:init_mappings()
  augroup END
endfunction

" }}}1

function! s:init_mappings() abort " {{{1
  call targets#mappings#extend({'e': {'tex_env': [{}]}})
  call targets#mappings#extend({'c': {'tex_cmd': [{}]}})
endfunction

" }}}1
function! s:init_sources() abort " {{{1
  call targets#sources#register('tex_env', function('vimtex#text_obj#envtargets#new'))
  call targets#sources#register('tex_cmd', function('vimtex#text_obj#cmdtargets#new'))
endfunction

" }}}1
