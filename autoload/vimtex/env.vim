" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#env#init_buffer() " {{{1
  nnoremap <silent><buffer> <plug>(vimtex-env-delete)
        \ :call vimtex#env#delete('env_tex')<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change)
        \ :call vimtex#env#change_prompt('env_tex')<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-delete-math)
        \ :call vimtex#env#delete('env_math')<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-change-math)
        \ :call vimtex#env#change_prompt('env_math')<cr>

  nnoremap <silent><buffer> <plug>(vimtex-env-toggle-star)
        \ :call vimtex#env#toggle_star()<cr>
endfunction

" }}}1

function! vimtex#env#change(open, close, new) " {{{1
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

  if a:new ==# ''
    silent! call repeat#set("\<plug>(vimtex-env-delete)", v:count)
  else
    silent! call repeat#set(
          \ "\<plug>(vimtex-env-change)" . a:new . '', v:count)
  endif
endfunction

function! vimtex#env#change_prompt(type) " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding(a:type)
  if empty(l:open) | return | endif

  let l:name = get(l:open, 'name', l:open.match)

  let s:env_name = l:name
  let l:new_env = vimtex#echo#input({
        \ 'prompt' : 'Change surrounding environment: ',
        \ 'default' : l:name,
        \ 'complete' : 'customlist,vimtex#env#input_complete',
        \})

  if empty(l:new_env) | return | endif

  call vimtex#env#change(l:open, l:close, l:new_env)
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

  if a:type ==# 'env_tex'
    silent! call repeat#set("\<plug>(vimtex-env-delete)", v:count)
  elseif a:type ==# 'env_math'
    silent! call repeat#set("\<plug>(vimtex-env-delete-math)", v:count)
  endif
endfunction

function! vimtex#env#toggle_star() " {{{1
  let [l:open, l:close] = vimtex#delim#get_surrounding('env_tex')
  if empty(l:open) | return | endif

  call vimtex#env#change(l:open, l:close,
        \ l:open.starred ? l:open.name : l:open.name . '*')

  silent! call repeat#set("\<plug>(vimtex-env-toggle-star)", v:count)
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
