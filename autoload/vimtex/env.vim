" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#env#init_buffer() abort " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-env-delete)
        \ :<c-u>call <sid>operator_setup('delete', 'env_tex')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change)
        \ :<c-u>call <sid>operator_setup('change', 'env_tex')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-delete-math)
        \ :<c-u>call <sid>operator_setup('delete', 'env_math')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change-math)
        \ :<c-u>call <sid>operator_setup('change', 'env_math')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-toggle-star)
        \ :<c-u>call <sid>operator_setup('toggle_star', '')<bar>normal! g@l<cr>
endfunction

" }}}1

function! vimtex#env#change(open, close, new) abort " {{{1
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

  let l:line = getline(a:open.lnum)
  call setline(a:open.lnum,
        \   strpart(l:line, 0, a:open.cnum-1)
        \ . l:beg
        \ . strpart(l:line, a:open.cnum + len(a:open.match) - 1))

  let l:c1 = a:close.cnum
  let l:c2 = a:close.cnum + len(a:close.match) - 1
  if a:open.lnum == a:close.lnum
    let n = len(l:beg) - len(a:open.match)
    let l:c1 += n
    let l:c2 += n
    let pos = vimtex#pos#get_cursor()
    if pos[2] > a:open.cnum + len(a:open.match) - 1
      let pos[2] += n
      call vimtex#pos#set_cursor(pos)
    endif
  endif

  let l:line = getline(a:close.lnum)
  call setline(a:close.lnum,
        \ strpart(l:line, 0, l:c1-1) . l:end . strpart(l:line, l:c2))
endfunction

function! vimtex#env#change_surrounding_to(type, new) abort " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open) | return | endif

  return vimtex#env#change(l:open, l:close, a:new)
endfunction

function! vimtex#env#delete(type) abort " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open) | return | endif

  if a:type ==# 'env_tex'
    call vimtex#cmd#delete_all(l:close)
    call vimtex#cmd#delete_all(l:open)
  else
    call l:close.remove()
    call l:open.remove()
  endif

  if getline(l:close.lnum) =~# '^\s*$'
    execute l:close.lnum . 'd _'
  endif

  if getline(l:open.lnum) =~# '^\s*$'
    execute l:open.lnum . 'd _'
  endif
endfunction

function! vimtex#env#toggle_star() abort " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env_tex')
  if empty(l:open) | return | endif

  call vimtex#env#change(l:open, l:close,
        \ l:open.starred ? l:open.name : l:open.name . '*')
endfunction

" }}}1

function! vimtex#env#is_inside(env) abort " {{{1
  let l:re_start = '\\begin\s*{' . a:env . '\*\?}'
  let l:re_end = '\\end\s*{' . a:env . '\*\?}'
  try
    return searchpairpos(l:re_start, '', l:re_end, 'bnW', '', 0, 100)
  catch /E118/
    let l:stopline = max([line('.') - 500, 1])
    return searchpairpos(l:re_start, '', l:re_end, 'bnW', '', l:stopline)
  endtry
endfunction

" }}}1
function! vimtex#env#input_complete(lead, cmdline, pos) abort " {{{1
  let l:cands = map(vimtex#complete#complete('env', '', '\begin'), 'v:val.word')

  " Never include document and remove current env (place it first)
  call filter(l:cands, 'index([''document'', s:env_name], v:val) < 0')

  " Always include current env and displaymath
  let l:cands = [s:env_name] + l:cands + ['\[']

  return filter(l:cands, 'v:val =~# ''^' . a:lead . '''')
endfunction

" }}}1

function! s:change_prompt(type) abort " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open) | return | endif

  if g:vimtex_env_change_autofill
    let l:name = get(l:open, 'name', l:open.match)
    let s:env_name = l:name
    return vimtex#echo#input({
          \ 'prompt' : 'Change surrounding environment: ',
          \ 'default' : l:name,
          \ 'complete' : 'customlist,vimtex#env#input_complete',
          \})
  else
    let l:name = get(l:open, 'name', l:open.is_open
          \ ? l:open.match . ' ... ' . l:open.corr
          \ : l:open.match . ' ... ' . l:open.corr)
    let s:env_name = l:name
    return vimtex#echo#input({
          \ 'info' :
          \   ['Change surrounding environment: ', ['VimtexWarning', l:name]],
          \ 'complete' : 'customlist,vimtex#env#input_complete',
          \})
  endif
endfunction

" }}}1

function! s:operator_setup(operator, type) abort " {{{1
  let &opfunc = s:snr() . 'operator_function'

  let s:operator_abort = 0
  let s:operator = a:operator
  let s:operator_type = a:type

  " Ask for user input if necessary/relevant
  if s:operator ==# 'change'
    let l:new_env = s:change_prompt(s:operator_type)
    if empty(l:new_env)
      let s:operator_abort = 1
      return
    endif

    let s:operator_name = l:new_env
  endif
endfunction

" }}}1
function! s:operator_function(_) abort " {{{1
  if get(s:, 'operator_abort', 0) | return | endif

  let l:type = get(s:, 'operator_type', '')
  let l:name = get(s:, 'operator_name', '')

  execute 'call vimtex#env#' . {
        \   'change': 'change_surrounding_to(l:type, l:name)',
        \   'delete': 'delete(l:type)',
        \   'toggle_star': 'toggle_star()',
        \ }[s:operator]
endfunction

" }}}1
function! s:snr() abort " {{{1
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" }}}1
