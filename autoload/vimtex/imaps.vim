" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#imaps#init_buffer() abort " {{{1
  if !g:vimtex_imaps_enabled | return | endif

  " Store mappings in buffer
  if !exists('b:vimtex_imaps')
    let b:vimtex_imaps = []
  endif

  "
  " Create imaps
  "
  let l:maps = g:vimtex_imaps_list
  for l:disable in g:vimtex_imaps_disabled
    let l:maps = filter(l:maps, {_, x -> x.lhs !=# l:disable})
  endfor
  for l:map in l:maps + get(s:, 'custom_maps', [])
    call s:create_map(l:map)
  endfor

  "
  " Add mappings and commands
  "
  command! -buffer  VimtexImapsList            call vimtex#imaps#list()
  nnoremap <buffer> <plug>(vimtex-imaps-list) :call vimtex#imaps#list()<cr>
endfunction

" }}}1

function! vimtex#imaps#add_map(map) abort " {{{1
  let s:custom_maps = get(s:, 'custom_maps', []) + [a:map]

  if exists('b:vimtex_imaps')
    call s:create_map(a:map)
  endif
endfunction

" }}}1
function! vimtex#imaps#list() abort " {{{1
  let l:maps = b:vimtex_imaps

  silent new VimTeX\ imaps

  for l:map in l:maps
    call append('$', printf('%5S  ->  %-30S %S',
          \ get(l:map, 'leader', g:vimtex_imaps_leader) . l:map.lhs,
          \ l:map.rhs,
          \ get(l:map, 'wrapper', 'vimtex#imaps#wrap_math')))
  endfor
  0delete _

  nnoremap <silent><buffer><nowait> q     :bwipeout<cr>
  nnoremap <silent><buffer><nowait> <esc> :bwipeout<cr>

  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal concealcursor=nvic
  setlocal conceallevel=0
  setlocal cursorline
  setlocal nobuflisted
  setlocal nolist
  setlocal nospell
  setlocal noswapfile
  setlocal nowrap
  setlocal nonumber
  setlocal norelativenumber
  setlocal nomodifiable

  syntax match VimtexImapsLhs     /^.*\ze->/ nextgroup=VimtexImapsArrow
  syntax match VimtexImapsArrow   /->/       contained nextgroup=VimtexImapsRhs
  syntax match VimtexImapsRhs     /\s*\S*/   contained nextgroup=VimtexImapsWrapper
  syntax match VimtexImapsWrapper /.*/       contained
endfunction

" }}}1

"
" The imap generator
"
function! s:create_map(map) abort " {{{1
  if index(b:vimtex_imaps, a:map) >= 0 | return | endif
  let l:map = deepcopy(a:map)

  let l:leader = get(l:map, 'leader', g:vimtex_imaps_leader)
  if l:leader !=# '' && !hasmapto(l:leader, 'i')
    silent execute 'inoremap <silent><buffer><nowait>' l:leader . l:leader l:leader
  endif
  let l:lhs = l:leader . l:map.lhs

  let l:wrapper = get(l:map, 'wrapper', 'vimtex#imaps#wrap_math')
  if ! exists('*' . l:wrapper)
    echoerr 'VimTeX error: imaps wrapper does not exist!'
    echoerr '              ' . l:wrapper
    return
  endif

  " Some wrappers use a context which must be made available to the wrapper
  " function at run time.
  if has_key(l:map, 'context')
    execute 'let l:key = "' . escape(l:lhs, '<') . '"'
    let l:key .= l:map.rhs
    if !exists('b:vimtex_context')
      let b:vimtex_context = {}
    endif
    let b:vimtex_context[l:key] = l:map.context
  endif

  " The rhs may be evaluated before being passed to wrapper, unless expr is
  " disabled (which it is by default)
  if !get(l:map, 'expr')
    let l:map.rhs = string(l:map.rhs)
  endif

  silent execute 'inoremap <silent><buffer><nowait><expr>' l:lhs
        \ l:wrapper . '("' . escape(l:lhs, '\') . '", ' . l:map.rhs . ')'

  let b:vimtex_imaps += [l:map]
endfunction

" }}}1

"
" Wrappers
"
function! vimtex#imaps#wrap_trivial(lhs, rhs) abort " {{{1
  return a:rhs
endfunction

" }}}1
function! vimtex#imaps#wrap_math(lhs, rhs) abort " {{{1
  return vimtex#syntax#in_mathzone() ? a:rhs : a:lhs
endfunction

" }}}1
function! vimtex#imaps#wrap_environment(lhs, rhs) abort " {{{1
  let l:return = a:lhs
  let l:cursor = vimtex#pos#val(vimtex#pos#get_cursor())
  let l:value = 0

  for l:context in b:vimtex_context[a:lhs . a:rhs]
    if type(l:context) == v:t_string
      let l:envs = [l:context]
      let l:rhs = a:rhs
    elseif type(l:context) == v:t_dict
      let l:envs = l:context.envs
      let l:rhs = l:context.rhs
    endif

    for l:env in l:envs
      let l:candidate_value = vimtex#pos#val(vimtex#env#is_inside(l:env))
      if l:candidate_value > l:value
        let l:value = l:candidate_value
        let l:return = l:rhs
      endif
    endfor

    unlet l:context
  endfor

  return l:return
endfunction

" }}}1

"
" Special rhs styles
"
function! vimtex#imaps#style_math(command) " {{{1
  return vimtex#syntax#in_mathzone()
        \ ? '\' . a:command . '{' . nr2char(getchar()) . '}'
        \ : ''
endfunction

" }}}1
