" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#env#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_env_complete_list', [
        \ 'itemize',
        \ 'enumerate',
        \ 'description',
        \ 'center',
        \ 'figure',
        \ 'table',
        \ 'equation',
        \ 'multline',
        \ 'align',
        \ 'split',
        \ '\[',
        \ ])
endfunction

" }}}1
function! vimtex#env#init_script() " {{{1
endfunction

" }}}1
function! vimtex#env#init_buffer() " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-env-delete)
        \ :call vimtex#env#change('')<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change)
        \ :call vimtex#env#change_prompt()<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-toggle-star)
        \ :call vimtex#env#toggle_star()<cr>
endfunction

" }}}1

function! vimtex#env#change(new) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env')

  "
  " Set target environment
  "
  if a:new ==# ''
    let [l:beg, l:end] = ['', '']
  elseif a:new ==# '$'
    let [l:beg, l:end] = ['$', '$']
  elseif a:new ==# '$$'
    let [l:beg, l:end] = ['$$', '$$']
  elseif a:new ==# '\['
    let [l:beg, l:end] = ['\[', '\]']
  elseif a:new ==# '\('
    let [l:beg, l:end] = ['\(', '\)']
  else
    let l:beg = '\begin{' . a:new . '}'
    let l:end = '\end{' . a:new . '}'
  endif

  let l:line = getline(l:open.lnum)
  call setline(l:open.lnum,
        \   strpart(l:line, 0, l:open.cnum-1)
        \ . l:beg
        \ . strpart(l:line, l:open.cnum + len(l:open.match) - 1))

  let l:c1 = l:close.cnum
  let l:c2 = l:close.cnum + len(l:close.match) - 1
  if l:open.lnum == l:close.lnum
    let n = len(l:beg) - len(l:open.match)
    let l:c1 += n
    let l:c2 += n
    let pos = getpos('.')
    if pos[2] > l:open.cnum + len(l:open.match) - 1
      let pos[2] += n
      call setpos('.', pos)
    endif
  endif

  let l:line = getline(l:close.lnum)
  call setline(l:close.lnum,
        \ strpart(l:line, 0, l:c1-1) . l:end . strpart(l:line, l:c2))

  if a:new ==# ''
    silent! call repeat#set("\<plug>(vimtex-env-delete)", v:count)
  else
    silent! call repeat#set(
          \ "\<plug>(vimtex-env-change)" . a:new . '', v:count)
  endif
endfunction

function! vimtex#env#change_prompt() " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env')
  let l:name = l:open.type ==# 'env' ? l:open.name : l:open.type

  call vimtex#echo#status(['Change surrounding environment: ',
        \ ['VimtexWarning', l:name]])
  echohl VimtexMsg
  let l:new_env = input('> ', '', 'customlist,' . s:sidwrap('input_complete'))
  echohl None

  if empty(l:new_env)
    return
  else
    call vimtex#env#change(l:new_env)
  endif
endfunction

function! vimtex#env#toggle_star() " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env')
  if l:open.type !=# 'env' | return | endif

  call vimtex#env#change(l:open.name[-1:] ==# '*'
        \ ? l:open.name[:-2]
        \ : l:open.name . '*'
        \)

  silent! call repeat#set("\<plug>(vimtex-env-toggle-star)", v:count)
endfunction

" }}}1

function! s:sidwrap(func) " {{{1
  return matchstr(expand('<sfile>'), '\zs<SNR>\d\+_\ze.*$') . a:func
endfunction

" }}}1
function! s:input_complete(lead, cmdline, pos) " {{{1
  return filter(g:vimtex_env_complete_list, 'v:val =~# ''^' . a:lead . '''')
endfunction

" }}}1

" vim: fdm=marker sw=2
