" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_view_enabled', 1)
  if !g:vimtex_view_enabled | return | endif

  call vimtex#util#set_default('g:vimtex_view_method', 'general')
  call vimtex#util#set_default('g:vimtex_view_use_temp_files', 0)
endfunction

" }}}1
function! vimtex#view#init_buffer() " {{{1
  if !g:vimtex_view_enabled | return | endif

  "
  " Add viewer to the data blob (if it does not already exist)
  "
  if !has_key(b:vimtex, 'viewer')
    try
      let b:vimtex.viewer = vimtex#view#{g:vimtex_view_method}#new()
    catch /E117/
      call vimtex#echo#warning('viewer '
            \ . g:vimtex_view_method . ' does not exist!')
      call vimtex#echo#echo('- Please see :h g:vimtex_view_method')
      call vimtex#echo#wait()
      return
    endtry

    " Make the following code more concise
    let l:v = b:vimtex.viewer

    "
    " Add latexmk callback to callback hooks (if it exists)
    "
    if exists('*l:v.latexmk_callback')
      call add(g:vimtex_latexmk_callback_hooks, 'l:v.latexmk_callback')
    endif

    "
    " Create view and/or callback hooks (if they exist)
    "
    for point in ['view', 'callback']
      execute 'let hook = ''g:vimtex_view_'
            \ . g:vimtex_view_method . '_hook_' . point . ''''
      if exists(hook)
        execute 'let hookfunc = ''*'' . ' . hook
        if exists(hookfunc)
          execute 'let l:v.hook_' . point . ' = function(' . hook . ')'
        endif
      endif
    endfor
  endif

  "
  " Define commands
  "
  command! -buffer -nargs=? -complete=file VimtexView
        \ call b:vimtex.viewer.view(<q-args>)
  if has_key(b:vimtex.viewer, 'reverse_search')
    command! -buffer -nargs=* VimtexRSearch
          \ call b:vimtex.viewer.reverse_search()
  endif

  "
  " Define mappings
  "
  nnoremap <buffer> <plug>(vimtex-view)
        \ :call b:vimtex.viewer.view('')<cr>
  if has_key(b:vimtex.viewer, 'reverse_search')
    nnoremap <buffer> <plug>(vimtex-reverse-search)
          \ :call b:vimtex.viewer.reverse_search()<cr>
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
