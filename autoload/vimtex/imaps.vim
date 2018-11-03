" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#imaps#init_buffer() abort " {{{1
  if !g:vimtex_imaps_enabled | return | endif

  "
  " Create imaps
  "
  let l:maps = g:vimtex_imaps_list
  for l:disable in g:vimtex_imaps_disabled
    let l:maps = filter(l:maps, 'v:val.lhs !=# ''' . l:disable . '''')
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

  if exists('s:created_maps')
    call s:create_map(a:map)
  endif
endfunction

" }}}1
function! vimtex#imaps#list() abort " {{{1
  silent new vimtex\ imaps

  for l:map in s:created_maps
    call append('$', printf('%5S  ->  %-30S %S',
          \ get(l:map, 'leader', get(g:, 'vimtex_imaps_leader', '`')) . l:map.lhs,
          \ l:map.rhs,
          \ get(l:map, 'wrapper', 'vimtex#imaps#wrap_math')))
  endfor
  0delete _

  nnoremap <silent><nowait><buffer> q     :bwipeout<cr>
  nnoremap <silent><nowait><buffer> <esc> :bwipeout<cr>

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
  let l:leader = get(a:map, 'leader', get(g:, 'vimtex_imaps_leader', '`'))
  if l:leader !=# '' && !hasmapto(l:leader, 'i')
    silent execute 'inoremap <silent><nowait><buffer>' l:leader . l:leader l:leader
  endif
  let l:lhs = l:leader . a:map.lhs

  let l:wrapper = get(a:map, 'wrapper', 'vimtex#imaps#wrap_math')
  if ! exists('*' . l:wrapper)
    echoerr 'vimtex error: imaps wrapper does not exist!'
    echoerr '              ' . l:wrapper
    return
  endif

  " Some wrappers use a context which must be made available to the wrapper
  " function at run time.
  if has_key(a:map, 'context')
    execute 'let l:key = "' . escape(l:lhs, '<') . '"'
    let l:key .= a:map.rhs
    if !exists('b:vimtex_context')
      let b:vimtex_context = {}
    endif
    let b:vimtex_context[l:key] = a:map.context
  endif

  silent execute 'inoremap <expr><silent><nowait><buffer>' l:lhs
        \ l:wrapper . '("' . escape(l:lhs, '\') . '", ' . string(a:map.rhs) . ')'

  let s:created_maps += [a:map]
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
  return s:is_math() ? a:rhs : a:lhs
endfunction

" }}}1
function! vimtex#imaps#wrap_environment(lhs, rhs) abort " {{{1
  let l:return = a:lhs
  let l:cursor = vimtex#pos#val(vimtex#pos#get_cursor())
  let l:value = 0

  for l:context in b:vimtex_context[a:lhs . a:rhs]
    if type(l:context) == type('')
      let l:envs = [l:context]
      let l:rhs = a:rhs
    elseif type(l:context) == type({})
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
" Helpers
"
function! s:is_math() abort " {{{1
  return match(map(synstack(line('.'), max([col('.') - 1, 1])),
        \ 'synIDattr(v:val, ''name'')'), '^texMathZone[A-Z]S\?$') >= 0
endfunction

" }}}1


" {{{1 Initialize module

let s:created_maps = []

" }}}1
