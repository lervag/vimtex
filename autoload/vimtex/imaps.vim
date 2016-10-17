" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#imaps#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_imaps_enabled', 1)
  call vimtex#util#set_default('g:vimtex_imaps_leader', '`')
  call vimtex#util#set_default('g:vimtex_imaps_disabled', [])
  call vimtex#util#set_default('g:vimtex_imaps_list', [
        \ { 'lhs' : '0',  'rhs' : '\emptyset' },
        \ { 'lhs' : '6',  'rhs' : '\partial' },
        \ { 'lhs' : '8',  'rhs' : '\infty' },
        \ { 'lhs' : '=',  'rhs' : '\equiv' },
        \ { 'lhs' : '\',  'rhs' : '\setminus' },
        \ { 'lhs' : '.',  'rhs' : '\cdot' },
        \ { 'lhs' : '*',  'rhs' : '\times' },
        \ { 'lhs' : '<',  'rhs' : '\langle' },
        \ { 'lhs' : '>',  'rhs' : '\rangle' },
        \ { 'lhs' : '<=', 'rhs' : '\leq' },
        \ { 'lhs' : '>=', 'rhs' : '\geq' },
        \ { 'lhs' : '[',  'rhs' : '\subseteq' },
        \ { 'lhs' : ']',  'rhs' : '\supseteq' },
        \ { 'lhs' : '(',  'rhs' : '\subset' },
        \ { 'lhs' : ')',  'rhs' : '\supset' },
        \ { 'lhs' : 'A',  'rhs' : '\forall' },
        \ { 'lhs' : 'E',  'rhs' : '\exists' },
        \ { 'lhs' : 'qj', 'rhs' : '\downarrow' },
        \ { 'lhs' : 'qJ', 'rhs' : '\Downarrow' },
        \ { 'lhs' : 'qk', 'rhs' : '\uparrow' },
        \ { 'lhs' : 'qK', 'rhs' : '\Uparrow' },
        \ { 'lhs' : 'qh', 'rhs' : '\leftarrow' },
        \ { 'lhs' : 'qH', 'rhs' : '\Leftarrow' },
        \ { 'lhs' : 'ql', 'rhs' : '\rightarrow' },
        \ { 'lhs' : 'qL', 'rhs' : '\Rightarrow' },
        \ { 'lhs' : 'a',  'rhs' : '\alpha' },
        \ { 'lhs' : 'b',  'rhs' : '\beta' },
        \ { 'lhs' : 'c',  'rhs' : '\chi' },
        \ { 'lhs' : 'd',  'rhs' : '\delta' },
        \ { 'lhs' : 'e',  'rhs' : '\epsilon' },
        \ { 'lhs' : 'f',  'rhs' : '\phi' },
        \ { 'lhs' : 'g',  'rhs' : '\gamma' },
        \ { 'lhs' : 'h',  'rhs' : '\eta' },
        \ { 'lhs' : 'i',  'rhs' : '\iota' },
        \ { 'lhs' : 'k',  'rhs' : '\kappa' },
        \ { 'lhs' : 'l',  'rhs' : '\lambda' },
        \ { 'lhs' : 'm',  'rhs' : '\mu' },
        \ { 'lhs' : 'n',  'rhs' : '\nu' },
        \ { 'lhs' : 'p',  'rhs' : '\pi' },
        \ { 'lhs' : 'q',  'rhs' : '\theta' },
        \ { 'lhs' : 'r',  'rhs' : '\rho' },
        \ { 'lhs' : 's',  'rhs' : '\sigma' },
        \ { 'lhs' : 't',  'rhs' : '\tau' },
        \ { 'lhs' : 'y',  'rhs' : '\psi' },
        \ { 'lhs' : 'u',  'rhs' : '\upsilon' },
        \ { 'lhs' : 'w',  'rhs' : '\omega' },
        \ { 'lhs' : 'z',  'rhs' : '\zeta' },
        \ { 'lhs' : 'x',  'rhs' : '\xi' },
        \ { 'lhs' : 'G',  'rhs' : '\Gamma' },
        \ { 'lhs' : 'D',  'rhs' : '\Delta' },
        \ { 'lhs' : 'F',  'rhs' : '\Phi' },
        \ { 'lhs' : 'G',  'rhs' : '\Gamma' },
        \ { 'lhs' : 'L',  'rhs' : '\Lambda' },
        \ { 'lhs' : 'P',  'rhs' : '\Pi' },
        \ { 'lhs' : 'Q',  'rhs' : '\Theta' },
        \ { 'lhs' : 'S',  'rhs' : '\Sigma' },
        \ { 'lhs' : 'U',  'rhs' : '\Upsilon' },
        \ { 'lhs' : 'W',  'rhs' : '\Omega' },
        \ { 'lhs' : 'X',  'rhs' : '\Xi' },
        \ { 'lhs' : 'Y',  'rhs' : '\Psi' },
        \ { 'lhs' : 've', 'rhs' : '\varepsilon' },
        \ { 'lhs' : 'vf', 'rhs' : '\varphi' },
        \ { 'lhs' : 'vk', 'rhs' : '\varkappa' },
        \ { 'lhs' : 'vq', 'rhs' : '\vartheta' },
        \ { 'lhs' : 'vr', 'rhs' : '\varrho' },
        \])
endfunction

" }}}1
function! vimtex#imaps#init_script() " {{{1
  call vimtex#util#set_highlight('VimtexImapsLhs', 'ModeMsg')
  call vimtex#util#set_highlight('VimtexImapsArrow', 'Comment')
  call vimtex#util#set_highlight('VimtexImapsRhs', 'ModeMsg')
  call vimtex#util#set_highlight('VimtexImapsWrapper', 'Type')

  let s:created_maps = []
endfunction

" }}}1
function! vimtex#imaps#init_buffer() " {{{1
  if !g:vimtex_imaps_enabled | return | endif

  " Container for wrapper contexts
  let b:vimtex_context = {}

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

function! vimtex#imaps#add_map(map) " {{{1
  let s:custom_maps = get(s:, 'custom_maps', []) + [a:map]

  if exists('s:created_maps')
    call s:create_map(a:map)
  endif
endfunction

" }}}1
function! vimtex#imaps#list() " {{{1
  silent new vimtex\ imaps

  for l:map in s:created_maps
    call append('$', printf('%5S  ->  %-30S %S',
          \ get(l:map, 'leader', g:vimtex_imaps_leader) . l:map.lhs,
          \ l:map.rhs,
          \ get(l:map, 'wrapper', 'vimtex#imaps#wrap_math')))
  endfor
  0delete _

  nnoremap <silent><buffer> q     :bwipeout<cr>
  nnoremap <silent><buffer> <esc> :bwipeout<cr>

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
function! s:create_map(map) " {{{1
  let l:leader = get(a:map, 'leader', g:vimtex_imaps_leader)
  if l:leader !=# '' && !hasmapto(l:leader, 'i')
    silent execute 'inoremap <silent><buffer>' l:leader . l:leader l:leader
  endif
  let l:lhs = l:leader . a:map.lhs

  let l:wrapper = get(a:map, 'wrapper', 'vimtex#imaps#wrap_math')
  if ! exists('*' . l:wrapper)
    echoerr 'vimtex error: imaps wrapper does not exist!'
    echoerr '              ' . l:wrapper
    return
  endif

  " Some wrappers use a context which must be made available to the wrapper
  " function in run time.
  if has_key(a:map, 'context')
    execute 'let l:key = "' . escape(l:lhs, '<') . '"'
    let b:vimtex_context[l:key] = a:map.context
  endif

  silent execute 'inoremap <expr><silent><buffer>' l:lhs
        \ l:wrapper . '("' . escape(l:lhs, '\') . '", ' . string(a:map.rhs) . ')'

  let s:created_maps += [a:map]
endfunction

" }}}1

"
" Wrappers
"
function! vimtex#imaps#wrap_trivial(lhs, rhs) " {{{1
  return a:rhs
endfunction

" }}}1
function! vimtex#imaps#wrap_math(lhs, rhs) " {{{1
  return s:is_math() ? a:rhs : a:lhs
endfunction

" }}}1
function! vimtex#imaps#wrap_environment(lhs, rhs) " {{{1
  for l:env in b:vimtex_context[a:lhs]
    if vimtex#env#is_inside(l:env)
      return a:rhs
    endif
  endfor
  return a:lhs
endfunction

" }}}1

"
" Helpers
"
function! s:is_math() " {{{1
  return match(map(synstack(line('.'), max([col('.') - 1, 1])),
        \ 'synIDattr(v:val, ''name'')'), '^texMathZone[A-Z]S\?$') >= 0
endfunction

" }}}1

" vim: fdm=marker sw=2
