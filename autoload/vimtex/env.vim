" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#env#init_buffer() " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-env-delete)
        \ :<c-u>call <sid>setup_operator('delete', 'env_tex')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change)
        \ :<c-u>call <sid>setup_operator('change', 'env_tex')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-delete-math)
        \ :<c-u>call <sid>setup_operator('delete', 'env_math')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change-math)
        \ :<c-u>call <sid>setup_operator('change', 'env_math')<bar>normal! g@l<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-toggle-star)
        \ :<c-u>call <sid>setup_operator('toggle_star', '')<bar>normal! g@l<cr>
endfunction

" }}}1

function! vimtex#env#change(...) " {{{1
  if a:0
    let [l:open, l:close, l:new] = a:000
  else
    let [l:open, l:close] = vimtex#delim#get_surrounding(s:type)
    if empty(l:open) | return | endif
    let l:new = s:new_env
  endif
  "
  " Set target environment
  "
  if l:new ==# ''
    let [l:beg, l:end] = ['', '']
  elseif l:new ==# '$'
    let [l:beg, l:end] = ['$', '$']
  elseif l:new ==# '$$'
    let [l:beg, l:end] = ['$$', '$$']
  elseif l:new ==# '\['
    let [l:beg, l:end] = ['\[', '\]']
  elseif l:new ==# '\('
    let [l:beg, l:end] = ['\(', '\)']
  else
    let l:beg = '\begin{' . l:new . '}'
    let l:end = '\end{' . l:new . '}'
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
    let pos = vimtex#pos#get_cursor()
    if pos[2] > l:open.cnum + len(l:open.match) - 1
      let pos[2] += n
      call vimtex#pos#set_cursor(pos)
    endif
  endif

  let l:line = getline(l:close.lnum)
  call setline(l:close.lnum,
        \ strpart(l:line, 0, l:c1-1) . l:end . strpart(l:line, l:c2))
endfunction

function! vimtex#env#change_prompt(type) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open) | return | endif


  if g:vimtex_env_change_autofill
    let l:name = get(l:open, 'name', l:open.match)
    let s:env_name = l:name
    let l:new_env = vimtex#echo#input({
          \ 'prompt' : 'Change surrounding environment: ',
          \ 'default' : l:name,
          \ 'complete' : 'customlist,vimtex#env#input_complete',
          \})
  else
    let l:name = get(l:open, 'name', l:open.is_open
          \ ? l:open.match . ' ... ' . l:open.corr
          \ : l:open.match . ' ... ' . l:open.corr)
    let s:env_name = l:name
    let l:new_env = vimtex#echo#input({
          \ 'info' :
          \   ['Change surrounding environment: ', ['VimtexWarning', l:name]],
          \ 'complete' : 'customlist,vimtex#env#input_complete',
          \})
  endif
  return l:new_env
endfunction

function! vimtex#env#delete(type) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open) | return | endif

  call vimtex#cmd#delete_all(l:close)
  if getline(l:close.lnum) =~# '^\s*$'
    execute l:close.lnum . 'd _'
  endif

  call vimtex#cmd#delete_all(l:open)
  if getline(l:open.lnum) =~# '^\s*$'
    execute l:open.lnum . 'd _'
  endif
endfunction

function! vimtex#env#toggle_star() " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env_tex')
  if empty(l:open) | return | endif

  call vimtex#env#change(l:open, l:close,
        \ l:open.starred ? l:open.name : l:open.name . '*')
endfunction

" }}}1

function! s:setup_operator(operator, type) abort " {{{1
  let [s:operator, s:type] = [a:operator, a:type]
  if s:operator ==# 'change'
    let l:new_env = vimtex#env#change_prompt(s:type)
    if empty(l:new_env) | return | endif
    let s:new_env = l:new_env
  endif
  let &opfunc = s:snr() . 'opfunc'
endfunction

" }}}1
function! s:opfunc(_) abort " {{{1
  call call('vimtex#env#' . s:operator, s:operator ==# 'delete' ? [s:type] : [])
endfunction

" }}}1
function! s:snr() abort " {{{1
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" }}}1

function! vimtex#env#is_inside(env) " {{{1
  let l:stopline = max([line('.') - 50, 1])
  return searchpairpos('\\begin\s*{' . a:env . '\*\?}', '',
        \ '\\end\s*{' . a:env . '\*\?}', 'bnW', '', l:stopline)
endfunction

" }}}1
function! vimtex#env#input_complete(lead, cmdline, pos) " {{{1
  try
    let l:cands = vimtex#util#uniq(sort(
          \ map(filter(vimtex#parser#tex(b:vimtex.tex, { 'detailed' : 0 }),
          \          'v:val =~# ''\\begin'''),
          \   'matchstr(v:val, ''\\begin{\zs\k*\ze\*\?}'')')))

    " Never include document and remove current env (place it first)
    call filter(l:cands, 'index([''document'', s:env_name], v:val) < 0')
  catch
    let l:cands = []
  endtry

  " Always include current env and displaymath
  let l:cands = [s:env_name] + l:cands + ['\[']

  return filter(l:cands, 'v:val =~# ''^' . a:lead . '''')
endfunction

" }}}1
