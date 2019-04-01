" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#init_buffer() abort " {{{1
  if !g:vimtex_view_enabled | return | endif

  command! -buffer -nargs=? -complete=file VimtexView
        \ call b:vimtex.viewer.view(<q-args>)
  if has_key(b:vimtex.viewer, 'reverse_search')
    command! -buffer -nargs=* VimtexRSearch
          \ call b:vimtex.viewer.reverse_search()
  endif

  nnoremap <buffer> <plug>(vimtex-view)
        \ :call b:vimtex.viewer.view('')<cr>
  if has_key(b:vimtex.viewer, 'reverse_search')
    nnoremap <buffer> <plug>(vimtex-reverse-search)
          \ :call b:vimtex.viewer.reverse_search()<cr>
  endif
endfunction

" }}}1
function! vimtex#view#init_state(state) abort " {{{1
  if !g:vimtex_view_enabled | return | endif
  if has_key(a:state, 'viewer') | return | endif

  try
    let a:state.viewer = vimtex#view#{g:vimtex_view_method}#new()
  catch /E117/
    call vimtex#log#warning(
          \ 'Invalid viewer: ' . g:vimtex_view_method,
          \ 'Please see :h g:vimtex_view_method')
    return
  endtry

  " Make the following code more concise
  let l:v = a:state.viewer

  "
  " Add compiler callback to callback hooks (if it exists)
  "
  if exists('*l:v.compiler_callback')
    call add(g:vimtex_compiler_callback_hooks,
          \ 'b:vimtex.viewer.compiler_callback')
  endif

  "
  " Create view and/or callback hooks (if they exist)
  "
  for l:point in ['view', 'callback']
    execute 'let l:hook = ''g:vimtex_view_'
          \ . g:vimtex_view_method . '_hook_' . l:point . ''''
    if exists(l:hook)
      execute 'let hookfunc = ''*'' . ' . l:hook
      if exists(hookfunc)
        execute 'let l:v.hook_' . l:point . ' = function(' . l:hook . ')'
      endif
    endif
  endfor
endfunction

" }}}1

function! vimtex#view#reverse_goto(line, filename) abort " {{{1
  if mode() ==# 'i' | stopinsert | endif

  let l:file = resolve(a:filename)

  " Open file if necessary
  if !bufexists(l:file)
    if filereadable(l:file)
      execute 'silent edit' l:file
    else
      call vimtex#log#warning("Reverse goto failed for file:\n" . l:file)
      return
    endif
  endif

  " Go to correct buffer and line
  let l:bufnr = bufnr(l:file)
  let l:winnr = bufwinnr(l:file)
  execute l:winnr >= 0
        \ ? l:winnr . 'wincmd w'
        \ : 'buffer ' . l:bufnr

  execute 'normal!' a:line . 'G'
  normal! zMzvzz

  " Attempt to focus Vim
  if executable('pstree') && executable('xdotool')
    let l:pids = reverse(split(system('pstree -s -p ' . getpid()), '\D\+'))

    let l:xwinids = []
    call map(copy(l:pids), 'extend(l:xwinids, reverse(split('
          \ . "system('xdotool search --onlyvisible --pid ' . v:val)"
          \ . ')))')
    call filter(l:xwinids, '!empty(v:val)')

    if !empty(l:xwinids)
      call system('xdotool windowactivate ' . l:xwinids[0] . ' &')
      call feedkeys("\<c-l>", 'tn')
    endif
  endif
endfunction

" }}}1
