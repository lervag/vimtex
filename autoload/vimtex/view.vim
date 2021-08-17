" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#init_buffer() abort " {{{1
  if !g:vimtex_view_enabled | return | endif

  command! -buffer -nargs=? -complete=file VimtexView
        \ call vimtex#view#view(<q-args>)
  if has_key(b:vimtex.viewer, 'reverse_search')
    command! -buffer -nargs=* VimtexViewRSearch
         \ call vimtex#view#reverse_search()
  endif

  nnoremap <buffer> <plug>(vimtex-view) :VimtexView<cr>
  if has_key(b:vimtex.viewer, 'reverse_search')
    nnoremap <buffer> <plug>(vimtex-reverse-search) :VimtexViewRSearch<cr>
  endif
endfunction

" }}}1
function! vimtex#view#init_state(state) abort " {{{1
  if !g:vimtex_view_enabled | return | endif
  if has_key(a:state, 'viewer') | return | endif

  if g:vimtex_view_use_temp_files
    augroup vimtex_view_buffer
      autocmd User VimtexEventCompileSuccess call b:vimtex.viewer.copy_files()
    augroup END
  endif

  try
    let a:state.viewer = vimtex#view#{g:vimtex_view_method}#new()
  catch /E117/
    call vimtex#log#warning(
          \ 'Invalid viewer: ' . g:vimtex_view_method,
          \ 'Please see :h g:vimtex_view_method')
    return
  endtry
endfunction

" }}}1

function! vimtex#view#view(...) abort " {{{1
  if exists('*b:vimtex.viewer.view')
    call b:vimtex.viewer.view(a:0 > 0 ? a:1 : '')
  endif
endfunction

" }}}1
function! vimtex#view#reverse_search() abort " {{{1
  if exists('*b:vimtex.viewer.reverse_search')
    call b:vimtex.viewer.reverse_search()
  endif
endfunction

" }}}1
function! vimtex#view#not_readable(output) abort " {{{1
  if filereadable(a:output) | return 0 | endif

  call vimtex#log#warning('Viewer cannot read PDF file!', a:output)
  return 1
endfunction

" }}}1

function! vimtex#view#reverse_goto(line, filename) abort " {{{1
  if mode() ==# 'i' | stopinsert | endif

  let l:file = resolve(a:filename)

  " Open file if necessary
  if !bufloaded(l:file)
    if filereadable(l:file)
      try
        execute g:vimtex_view_reverse_search_edit_cmd l:file
      catch
        call vimtex#log#warning([
              \ 'Reverse goto failed!',
              \ printf('Command error: %s %s',
              \        g:vimtex_view_reverse_search_edit_cmd, l:file)])
        return
      endtry
    else
      call vimtex#log#warning([
            \ 'Reverse goto failed!',
            \ printf('File not readable: "%s"', l:file)])
      return
    endif
  endif

  " Get buffer, window, and tab numbers
  " * If tab/window exists, switch to it/them
  let l:bufnr = bufnr(l:file)
  try
    let [l:winid] = win_findbuf(l:bufnr)
    let [l:tabnr, l:winnr] = win_id2tabwin(l:winid)
    execute l:tabnr . 'tabnext'
    execute l:winnr . 'wincmd w'
  catch
    execute g:vimtex_view_reverse_search_edit_cmd l:file
  endtry

  execute 'normal!' a:line . 'G'
  redraw

  " Attempt to focus Vim
  if executable('pstree') && executable('xdotool')
    let l:pids = reverse(split(system('pstree -s -p ' . getpid()), '\D\+'))

    let l:xwinids = []
    call map(copy(l:pids),
          \ {_, x -> extend(l:xwinids, reverse(split(system(
          \   'xdotool search --onlyvisible --pid ' . x))))})
    call filter(l:xwinids, '!empty(v:val)')

    if !empty(l:xwinids)
      call system('xdotool windowactivate ' . l:xwinids[0] . ' &')
      call feedkeys("\<c-l>", 'tn')
    endif
  endif

  if exists('#User#VimtexEventViewReverse')
    doautocmd <nomodeline> User VimtexEventViewReverse
  endif
endfunction

" }}}1
