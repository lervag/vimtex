" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#init() abort " {{{1
  if exists('#User#VimtexEventInitPre')
    doautocmd <nomodeline> User VimtexEventInitPre
  endif

  call vimtex#options#init()

  call s:init_state()
  call s:init_buffer()
  call s:init_default_mappings()

  if exists('#User#VimtexEventInitPost')
    doautocmd <nomodeline> User VimtexEventInitPost
  endif

  augroup vimtex_main
    autocmd!
    autocmd VimLeave * call s:quit()
  augroup END
endfunction

" }}}1

function! s:init_state() abort " {{{1
  call vimtex#state#init()
  call vimtex#state#init_local()
endfunction

" }}}1

function! s:init_buffer() abort " {{{1
  try
    let l:disabled_modules = s:init_buffer_{&filetype}()
  catch /E117/
    let l:disabled_modules = []
  endtry

  " Define autocommands
  augroup vimtex_buffers
    autocmd! * <buffer>
    autocmd BufFilePre  <buffer> call s:filename_changed_pre()
    autocmd BufFilePost <buffer> call s:filename_changed_post()
    autocmd BufUnload   <buffer> call s:buffer_deleted('unload')
    autocmd BufWipeout  <buffer> call s:buffer_deleted('wipe')
  augroup END

  " Initialize buffer settings for sub modules
  call extend(l:disabled_modules, get(b:vimtex, 'disabled_modules', []))
  for l:mod in filter(copy(s:modules),
        \ 'index(l:disabled_modules, v:val) < 0')
    try
      call vimtex#{l:mod}#init_buffer()
    catch /E117.*#init_/
    catch /E127.*vimtex#profile#/
    endtry
  endfor
endfunction

" }}}1
function! s:init_buffer_tex() abort " {{{1
  setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
  setlocal commentstring=\%\ %s

  for l:suf in [
        \ '.sty',
        \ '.cls',
        \ '.log',
        \ '.aux',
        \ '.bbl',
        \ '.out',
        \ '.blg',
        \ '.brf',
        \ '.cb',
        \ '.dvi',
        \ '.fdb_latexmk',
        \ '.fls',
        \ '.idx',
        \ '.ilg',
        \ '.ind',
        \ '.inx',
        \ '.pdf',
        \ '.synctex.gz',
        \ '.toc',
        \ ]
    execute 'set suffixes+=' . l:suf
  endfor
  setlocal suffixesadd=.tex,.sty,.cls
  setlocal iskeyword+=:
  setlocal includeexpr=vimtex#include#expr()

  let &l:include = g:vimtex#re#tex_include
  let &l:define  = '\v\\%('
        \ . '([egx]|mathchar|count|dimen|muskip|skip|toks)?def'
        \ . '|font'
        \ . '|(future)?let'
        \ . '|new(count|dimen|skip|muskip|box|toks|read|write|fam|insert)'
        \ . '|(re)?new(boolean|command|counter|environment'
        \ .   '|font|if|length|savebox|theorem(style)?)'
        \ . '|DeclareMathOperator'
        \ . '|bibitem%(\[[^]]*\])?'
        \ . ')'

  " Specify list of modules to disable
  return []
endfunction

" }}}1
function! s:init_buffer_bib() abort " {{{1
  setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
  setlocal commentstring=\%\ %s

  for l:suf in [
        \ '.sty',
        \ '.cls',
        \ '.log',
        \ '.aux',
        \ '.bbl',
        \ '.out',
        \ '.blg',
        \ '.brf',
        \ '.cb',
        \ '.dvi',
        \ '.fdb_latexmk',
        \ '.fls',
        \ '.idx',
        \ '.ilg',
        \ '.ind',
        \ '.inx',
        \ '.pdf',
        \ '.synctex.gz',
        \ '.toc',
        \ ]
    execute 'set suffixes+=' . l:suf
  endfor
  setlocal suffixesadd=.tex,.bib

  if g:vimtex_fold_bib_enabled
    call vimtex#fold#bib#init()
  endif

  " Specify list of modules to disable
  return [
        \ 'fold', 'matchparen', 'format', 'doc', 'imaps', 'delim',
        \ 'env', 'motion', 'complete',
        \]
endfunction

" }}}1

function! s:init_default_mappings() abort " {{{1
  if !g:vimtex_mappings_enabled | return | endif

  call s:map_prefixed(0, 'n', 'i', '<plug>(vimtex-info)')
  call s:map_prefixed(0, 'n', 'I', '<plug>(vimtex-info-full)')
  call s:map_prefixed(0, 'n', 'x', '<plug>(vimtex-reload)')
  call s:map_prefixed(0, 'n', 'X', '<plug>(vimtex-reload-state)')
  call s:map_prefixed(1, 'n', 's', '<plug>(vimtex-toggle-main)')
  call s:map_prefixed(0, 'n', 'q', '<plug>(vimtex-log)')
  call s:map_prefixed(1, 'n', 'a', '<plug>(vimtex-context-menu)')

  call s:map(0, 'n', 'ds$', '<plug>(vimtex-env-delete-math)')
  call s:map(0, 'n', 'cs$', '<plug>(vimtex-env-change-math)')
  call s:map(0, 'n', 'dse', '<plug>(vimtex-env-delete)')
  call s:map(0, 'n', 'cse', '<plug>(vimtex-env-change)')
  call s:map(0, 'n', 'tse', '<plug>(vimtex-env-toggle)')
  call s:map(0, 'n', 'tss', '<plug>(vimtex-env-toggle-star)')
  call s:map(0, 'n', 'ts$', '<plug>(vimtex-env-toggle-math)')
  call s:map(0, 'n', '<F6>', '<plug>(vimtex-env-surround-line)')
  call s:map(0, 'x', '<F6>', '<plug>(vimtex-env-surround-visual)')

  call s:map(0, 'n', 'dsc',  '<plug>(vimtex-cmd-delete)')
  call s:map(0, 'n', 'csc',  '<plug>(vimtex-cmd-change)')
  call s:map(0, 'n', 'tsc',  '<plug>(vimtex-cmd-toggle-star)')
  call s:map(0, 'n', 'tsf',  '<plug>(vimtex-cmd-toggle-frac)')
  call s:map(0, 'x', 'tsf',  '<plug>(vimtex-cmd-toggle-frac)')
  call s:map(0, 'n', 'tsb',  '<plug>(vimtex-cmd-toggle-break)')
  call s:map(0, 'i', '<F7>', '<plug>(vimtex-cmd-create)')
  call s:map(0, 'n', '<F7>', '<plug>(vimtex-cmd-create)')
  call s:map(0, 'x', '<F7>', '<plug>(vimtex-cmd-create)')

  call s:map(0, 'n', 'dsd', '<plug>(vimtex-delim-delete)')
  call s:map(0, 'n', 'csd', '<plug>(vimtex-delim-change-math)')
  call s:map(0, 'n', 'tsd', '<plug>(vimtex-delim-toggle-modifier)')
  call s:map(0, 'x', 'tsd', '<plug>(vimtex-delim-toggle-modifier)')
  call s:map(0, 'n', 'tsD', '<plug>(vimtex-delim-toggle-modifier-reverse)')
  call s:map(0, 'x', 'tsD', '<plug>(vimtex-delim-toggle-modifier-reverse)')
  call s:map(0, 'i', ']]',  '<plug>(vimtex-delim-close)')
  call s:map(0, 'n', '<F8>', '<plug>(vimtex-delim-add-modifiers)')

  if g:vimtex_compiler_enabled
    call s:map_prefixed(0, 'n', 'l', '<plug>(vimtex-compile)')
    call s:map_prefixed(0, 'n', 'o', '<plug>(vimtex-compile-output)')
    call s:map_prefixed(1, 'n', 'L', '<plug>(vimtex-compile-selected)')
    call s:map_prefixed(1, 'x', 'L', '<plug>(vimtex-compile-selected)')
    call s:map_prefixed(0, 'n', 'k', '<plug>(vimtex-stop)')
    call s:map_prefixed(0, 'n', 'K', '<plug>(vimtex-stop-all)')
    call s:map_prefixed(0, 'n', 'e', '<plug>(vimtex-errors)')
    call s:map_prefixed(0, 'n', 'c', '<plug>(vimtex-clean)')
    call s:map_prefixed(0, 'n', 'C', '<plug>(vimtex-clean-full)')
    call s:map_prefixed(0, 'n', 'g', '<plug>(vimtex-status)')
    call s:map_prefixed(0, 'n', 'G', '<plug>(vimtex-status-all)')
  endif

  if g:vimtex_motion_enabled
    " These are forced in order to overwrite matchit mappings
    call s:map(1, 'n', '%', '<plug>(vimtex-%)', 1)
    call s:map(1, 'x', '%', '<plug>(vimtex-%)', 1)
    call s:map(1, 'o', '%', '<plug>(vimtex-%)', 1)

    call s:map(1, 'n', ']]', '<plug>(vimtex-]])')
    call s:map(1, 'n', '][', '<plug>(vimtex-][)')
    call s:map(1, 'n', '[]', '<plug>(vimtex-[])')
    call s:map(1, 'n', '[[', '<plug>(vimtex-[[)')
    call s:map(1, 'x', ']]', '<plug>(vimtex-]])')
    call s:map(1, 'x', '][', '<plug>(vimtex-][)')
    call s:map(1, 'x', '[]', '<plug>(vimtex-[])')
    call s:map(1, 'x', '[[', '<plug>(vimtex-[[)')
    call s:map(1, 'o', ']]', '<plug>(vimtex-]])')
    call s:map(1, 'o', '][', '<plug>(vimtex-][)')
    call s:map(1, 'o', '[]', '<plug>(vimtex-[])')
    call s:map(1, 'o', '[[', '<plug>(vimtex-[[)')

    call s:map(1, 'n', ']M', '<plug>(vimtex-]M)')
    call s:map(1, 'n', ']m', '<plug>(vimtex-]m)')
    call s:map(1, 'n', '[M', '<plug>(vimtex-[M)')
    call s:map(1, 'n', '[m', '<plug>(vimtex-[m)')
    call s:map(1, 'x', ']M', '<plug>(vimtex-]M)')
    call s:map(1, 'x', ']m', '<plug>(vimtex-]m)')
    call s:map(1, 'x', '[M', '<plug>(vimtex-[M)')
    call s:map(1, 'x', '[m', '<plug>(vimtex-[m)')
    call s:map(1, 'o', ']M', '<plug>(vimtex-]M)')
    call s:map(1, 'o', ']m', '<plug>(vimtex-]m)')
    call s:map(1, 'o', '[M', '<plug>(vimtex-[M)')
    call s:map(1, 'o', '[m', '<plug>(vimtex-[m)')

    call s:map(1, 'n', ']N', '<plug>(vimtex-]N)')
    call s:map(1, 'n', ']n', '<plug>(vimtex-]n)')
    call s:map(1, 'n', '[N', '<plug>(vimtex-[N)')
    call s:map(1, 'n', '[n', '<plug>(vimtex-[n)')
    call s:map(1, 'x', ']N', '<plug>(vimtex-]N)')
    call s:map(1, 'x', ']n', '<plug>(vimtex-]n)')
    call s:map(1, 'x', '[N', '<plug>(vimtex-[N)')
    call s:map(1, 'x', '[n', '<plug>(vimtex-[n)')
    call s:map(1, 'o', ']N', '<plug>(vimtex-]N)')
    call s:map(1, 'o', ']n', '<plug>(vimtex-]n)')
    call s:map(1, 'o', '[N', '<plug>(vimtex-[N)')
    call s:map(1, 'o', '[n', '<plug>(vimtex-[n)')

    call s:map(1, 'n', ']R', '<plug>(vimtex-]R)')
    call s:map(1, 'n', ']r', '<plug>(vimtex-]r)')
    call s:map(1, 'n', '[R', '<plug>(vimtex-[R)')
    call s:map(1, 'n', '[r', '<plug>(vimtex-[r)')
    call s:map(1, 'x', ']R', '<plug>(vimtex-]R)')
    call s:map(1, 'x', ']r', '<plug>(vimtex-]r)')
    call s:map(1, 'x', '[R', '<plug>(vimtex-[R)')
    call s:map(1, 'x', '[r', '<plug>(vimtex-[r)')
    call s:map(1, 'o', ']R', '<plug>(vimtex-]R)')
    call s:map(1, 'o', ']r', '<plug>(vimtex-]r)')
    call s:map(1, 'o', '[R', '<plug>(vimtex-[R)')
    call s:map(1, 'o', '[r', '<plug>(vimtex-[r)')

    call s:map(1, 'n', ']/', '<plug>(vimtex-]/)')
    call s:map(1, 'n', ']*', '<plug>(vimtex-]*)')
    call s:map(1, 'n', '[/', '<plug>(vimtex-[/)')
    call s:map(1, 'n', '[*', '<plug>(vimtex-[*)')
    call s:map(1, 'x', ']/', '<plug>(vimtex-]/)')
    call s:map(1, 'x', ']*', '<plug>(vimtex-]*)')
    call s:map(1, 'x', '[/', '<plug>(vimtex-[/)')
    call s:map(1, 'x', '[*', '<plug>(vimtex-[*)')
    call s:map(1, 'o', ']/', '<plug>(vimtex-]/)')
    call s:map(1, 'o', ']*', '<plug>(vimtex-]*)')
    call s:map(1, 'o', '[/', '<plug>(vimtex-[/)')
    call s:map(1, 'o', '[*', '<plug>(vimtex-[*)')
  endif

  if g:vimtex_text_obj_enabled
    call s:map(0, 'x', 'id', '<plug>(vimtex-id)')
    call s:map(0, 'x', 'ad', '<plug>(vimtex-ad)')
    call s:map(0, 'o', 'id', '<plug>(vimtex-id)')
    call s:map(0, 'o', 'ad', '<plug>(vimtex-ad)')
    call s:map(0, 'x', 'i$', '<plug>(vimtex-i$)')
    call s:map(0, 'x', 'a$', '<plug>(vimtex-a$)')
    call s:map(0, 'o', 'i$', '<plug>(vimtex-i$)')
    call s:map(0, 'o', 'a$', '<plug>(vimtex-a$)')
    call s:map(1, 'x', 'iP', '<plug>(vimtex-iP)')
    call s:map(1, 'x', 'aP', '<plug>(vimtex-aP)')
    call s:map(1, 'o', 'iP', '<plug>(vimtex-iP)')
    call s:map(1, 'o', 'aP', '<plug>(vimtex-aP)')
    call s:map(1, 'x', 'im', '<plug>(vimtex-im)')
    call s:map(1, 'x', 'am', '<plug>(vimtex-am)')
    call s:map(1, 'o', 'im', '<plug>(vimtex-im)')
    call s:map(1, 'o', 'am', '<plug>(vimtex-am)')

    if vimtex#text_obj#targets#enabled()
      call vimtex#text_obj#targets#init()

      " These are handled explicitly to avoid conflict with gitgutter
      call s:map(0, 'x', 'ic', '<plug>(vimtex-targets-i)c')
      call s:map(0, 'x', 'ac', '<plug>(vimtex-targets-a)c')
      call s:map(0, 'o', 'ic', '<plug>(vimtex-targets-i)c')
      call s:map(0, 'o', 'ac', '<plug>(vimtex-targets-a)c')
    else
      if g:vimtex_text_obj_variant ==# 'targets'
        call vimtex#log#warning(
              \ "Ignoring g:vimtex_text_obj_variant = 'targets'"
              \ . " because 'g:loaded_targets' does not exist or is 0.")
      endif
      let g:vimtex_text_obj_variant = 'vimtex'

      call s:map(0, 'x', 'ie', '<plug>(vimtex-ie)')
      call s:map(0, 'x', 'ae', '<plug>(vimtex-ae)')
      call s:map(0, 'o', 'ie', '<plug>(vimtex-ie)')
      call s:map(0, 'o', 'ae', '<plug>(vimtex-ae)')
      call s:map(0, 'x', 'ic', '<plug>(vimtex-ic)')
      call s:map(0, 'x', 'ac', '<plug>(vimtex-ac)')
      call s:map(0, 'o', 'ic', '<plug>(vimtex-ic)')
      call s:map(0, 'o', 'ac', '<plug>(vimtex-ac)')
    endif
  endif

  if g:vimtex_toc_enabled
    call s:map_prefixed(0, 'n', 't', '<plug>(vimtex-toc-open)')
    call s:map_prefixed(0, 'n', 'T', '<plug>(vimtex-toc-toggle)')
  endif

  if has_key(b:vimtex, 'viewer')
    call s:map_prefixed(0, 'n', 'v', '<plug>(vimtex-view)')
    if !empty(maparg('<plug>(vimtex-reverse-search)', 'n'))
      call s:map_prefixed(1, 'n', 'r', '<plug>(vimtex-reverse-search)')
    endif
  endif

  if g:vimtex_imaps_enabled
    call s:map_prefixed(0, 'n', 'm', '<plug>(vimtex-imaps-list)')
  endif

  if g:vimtex_doc_enabled
    call s:map(1, 'n', 'K', '<plug>(vimtex-doc-package)')
  endif
endfunction

" }}}1

function! s:filename_changed_pre() abort " {{{1
  let s:filename_changed = expand('%:p') ==# b:vimtex.tex
endfunction

" }}}1
function! s:filename_changed_post() abort " {{{1
  if s:filename_changed
    let l:old = b:vimtex.tex
    let b:vimtex.tex = expand('%:p')
    let b:vimtex.root = fnamemodify(b:vimtex.tex, ':h')
    let b:vimtex.base = fnamemodify(b:vimtex.tex, ':t')
    let b:vimtex.name = fnamemodify(b:vimtex.tex, ':t:r')

    call vimtex#log#warning('Filename change detected')
    call vimtex#log#info('Old: ' . l:old)
    call vimtex#log#info('New: ' . b:vimtex.tex)

    if has_key(b:vimtex, 'compiler')
      if b:vimtex.compiler.is_running()
        call vimtex#compiler#stop()
        call vimtex#log#warning('Compilation stopped!')
      endif

      call vimtex#compiler#init_state(b:vimtex)
    endif
  endif
endfunction

" }}}1
function! s:buffer_deleted(reason) abort " {{{1
  "
  " We need a simple cache of buffer ids because a buffer unload might clear
  " buffer variables, so that a subsequent buffer wipe will not trigger a full
  " cleanup. By caching the buffer id, we should avoid this issue.
  "
  let s:buffer_cache = get(s:, 'buffer_cache', {})
  let l:file = expand('<afile>')

  if !has_key(s:buffer_cache, l:file)
    let s:buffer_cache[l:file] = getbufvar(l:file, 'vimtex_id', -1)
  endif

  if a:reason ==# 'wipe'
    call vimtex#state#cleanup(s:buffer_cache[l:file])
    call remove(s:buffer_cache, l:file)
  endif
endfunction

" }}}1
function! s:quit() abort " {{{1
  for l:state in vimtex#state#list_all()
    call l:state.cleanup()
  endfor

  call vimtex#cache#write_all()
endfunction

" }}}1

function! s:map_prefixed(ftype, mode, lhs, rhs) abort " {{{1
  let l:lhs = g:vimtex_mappings_prefix . a:lhs
  call s:map(a:ftype, a:mode, l:lhs, a:rhs)
endfunction

" }}}1
function! s:map(ftype, mode, lhs, rhs, ...) abort " {{{1
  if (a:ftype == 0
        \     || a:ftype == 1 && &filetype ==# 'tex'
        \     || a:ftype == 2 && &filetype ==# 'bib')
        \ && !hasmapto(a:rhs, a:mode)
        \ && index(get(g:vimtex_mappings_disable, a:mode, []), a:lhs) < 0
        \ && (a:0 > 0
        \     || g:vimtex_mappings_override_existing
        \     || empty(maparg(a:lhs, a:mode)))
    silent execute a:mode . 'map <silent><buffer><nowait>' a:lhs a:rhs
  endif
endfunction

" }}}1

" {{{1 Initialize module

let s:modules = map(
      \ glob(expand('<sfile>:r') . '/*.vim', 0, 1),
      \ { _, x -> fnamemodify(x, ':t:r') })
call remove(s:modules, index(s:modules, 'test'))

" }}}1
