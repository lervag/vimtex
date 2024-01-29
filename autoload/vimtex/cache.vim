" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#cache#init_buffer() abort " {{{1
  command! -buffer -nargs=1 VimtexClearCache call vimtex#cache#clear(<q-args>)
endfunction

" }}}1

function! vimtex#cache#path(name) abort " {{{1
  let l:root = s:root()
  if !isdirectory(l:root)
    call mkdir(l:root, 'p')
  endif

  return vimtex#paths#join(l:root, a:name)
endfunction

" }}}1
function! vimtex#cache#wrap(Func, name, ...) abort " {{{1
  if !has('lambda')
    throw 'error: vimtex#cache#wrap requires +lambda'
  endif

  let l:opts = a:0 > 0 ? a:1 : {}
  let l:cache = vimtex#cache#open(a:name, l:opts)

  function! CachedFunc(key) closure
    if l:cache.has(a:key)
      return l:cache.get(a:key)
    else
      return l:cache.set(a:key, a:Func(a:key))
    endif
  endfunction

  return function('CachedFunc')
endfunction

" }}}1

function! vimtex#cache#open(name, ...) abort " {{{1
  let l:opts = extend({
        \ 'local': v:false,
        \ 'default': 0,
        \ 'persistent': get(g:, 'vimtex_cache_persistent', v:true),
        \ 'validate': s:_version,
        \}, a:0 > 0 ? a:1 : {})

  let l:project_local = remove(l:opts, 'local')
  return s:cache_open(a:name, l:project_local, l:opts)
endfunction

" }}}1
function! vimtex#cache#close(name) abort " {{{1
  " Note: This will close BOTH local and global cache!

  for [l:name, l:cache] in s:cache_get_both(a:name)
    if !empty(l:cache) && has_key(s:caches, l:name)
      call l:cache.write()
      unlet s:caches[l:name]
    endif
  endfor
endfunction

" }}}1
function! vimtex#cache#clear(name) abort " {{{1
  if empty(a:name) | return | endif

  if a:name ==# 'ALL'
    return s:cache_clear_all()
  endif

  let l:persistent = get(g:, 'vimtex_cache_persistent', 1)
  for [l:name, l:cache] in s:cache_get_both(a:name)
    if !empty(l:cache)
      call l:cache.clear()
      unlet s:caches[l:name]
    elseif l:persistent
      let l:path = vimtex#cache#path(l:name . '.json')
      call delete(l:path)
    endif
  endfor
endfunction

" }}}1
function! vimtex#cache#write_all() abort " {{{1
  for l:cache in values(get(s:, 'caches', {}))
    call l:cache.write()
  endfor
endfunction

" }}}1

function! s:cache_open(name, project_local, opts) abort " {{{1
  let l:name = a:project_local ? s:local_name(a:name) : a:name

  let s:caches = get(s:, 'caches', {})
  if !has_key(s:caches, l:name)
    let l:path = vimtex#cache#path(l:name . '.json')
    let s:caches[l:name] = s:cache.init(l:path, a:opts)
  endif

  return s:caches[l:name]
endfunction

" }}}1
function! s:cache_get(name, ...) abort " {{{1
  let l:project_local = a:0 > 0 ? a:1 : v:false
  let l:name = l:project_local ? s:local_name(a:name) : a:name

  let s:caches = get(s:, 'caches', {})
  return [l:name, get(s:caches, l:name, {})]
endfunction

" }}}1
function! s:cache_get_both(name) abort " {{{1
  return map(
        \ [v:false, v:true],
        \ { _, x -> s:cache_get(a:name, x) }
        \)
endfunction

" }}}1
function! s:cache_clear_all() abort " {{{1
  " Delete cache state map
  unlet! s:caches

  if !get(g:, 'vimtex_cache_persistent', 1) | return | endif

  " Delete cache files
  for l:file in globpath(s:root(), '*.json', 0, 1)
    call delete(l:file)
  endfor
endfunction

" }}}1

let s:cache = {}

function! s:cache.init(path, opts) dict abort " {{{1
  let new = deepcopy(self)
  unlet new.init

  let new.data = {}
  let new.path = a:path
  let new.ftime = -1
  let new.default = a:opts.default

  let new.__validated = 0
  let new.__validation_value = deepcopy(a:opts.validate)
  if type(new.__validation_value) == v:t_dict
    let new.__validation_value._version = s:_version
  endif
  let new.data.__validate = deepcopy(new.__validation_value)

  if a:opts.persistent
    return extend(new, s:cache_persistent)
  endif

  return extend(new, s:cache_volatile)
endfunction

" }}}1

let s:cache_persistent = {
      \ 'type': 'persistent',
      \ 'modified': 0,
      \}
function! s:cache_persistent.validate() dict abort " {{{1
  let self.__validated = 1

  if type(self.data.__validate) != type(self.__validation_value)
        \ || self.data.__validate != self.__validation_value
    call self.clear()
    let self.data.__validate = deepcopy(self.__validation_value)
    call self.write()
  endif
endfunction

" }}}1
function! s:cache_persistent.get(key) dict abort " {{{1
  call self.read()

  if !has_key(self.data, a:key)
    let self.data[a:key] = deepcopy(self.default)
  endif

  return get(self.data, a:key)
endfunction

" }}}1
function! s:cache_persistent.has(key) dict abort " {{{1
  call self.read()

  return has_key(self.data, a:key)
endfunction

" }}}1
function! s:cache_persistent.set(key, value) dict abort " {{{1
  call self.read()

  let self.data[a:key] = a:value
  call self.write(1)

  return a:value
endfunction

" }}}1
function! s:cache_persistent.write(...) dict abort " {{{1
  call self.read()

  let l:modified = self.modified || a:0 > 0
  if !l:modified || empty(self.data) | return | endif

  try
    let l:encoded = json_encode(self.data)
    call writefile([l:encoded], self.path)
    let self.ftime = getftime(self.path)
    let self.modified = 0
  catch /E474:/
    call vimtex#log#warning(
          \ 'Could not encode cache "'
          \   . fnamemodify(self.path, ':t:r') . '"',
          \ string(self.data)
          \)
  endtry
endfunction

" }}}1
function! s:cache_persistent.read() dict abort " {{{1
  if getftime(self.path) <= self.ftime | return | endif

  let self.ftime = getftime(self.path)
  let l:contents = join(readfile(self.path))
  if empty(l:contents) | return | endif

  let l:data = json_decode(l:contents)

  if type(l:data) != v:t_dict
    call vimtex#log#warning(
          \ 'Inconsistent cache data while reading:',
          \ self.path,
          \ 'Decoded data type: ' . type(l:data)
          \)
    return
  endif

  call extend(self.data, l:data)

  if !self.__validated
    call self.validate()
  endif
endfunction

" }}}1
function! s:cache_persistent.clear() dict abort " {{{1
  let self.data = { '__validate': deepcopy(self.__validation_value) }
  let self.ftime = -1
  let self.modified = 0
  call delete(self.path)
endfunction

" }}}1

let s:cache_volatile = {
      \ 'type': 'volatile',
      \}
function! s:cache_volatile.get(key) dict abort " {{{1
  if !has_key(self.data, a:key)
    let self.data[a:key] = deepcopy(self.default)
  endif

  return get(self.data, a:key)
endfunction

" }}}1
function! s:cache_volatile.has(key) dict abort " {{{1
  return has_key(self.data, a:key)
endfunction

" }}}1
function! s:cache_volatile.set(key, value) dict abort " {{{1
  let self.data[a:key] = a:value
  let self.ftime = localtime()
  return a:value
endfunction

" }}}1
function! s:cache_volatile.write(...) dict abort " {{{1
endfunction

" }}}1
function! s:cache_volatile.read() dict abort " {{{1
endfunction

" }}}1
function! s:cache_volatile.clear() dict abort " {{{1
  let self.data = {}
  let self.ftime = -1
endfunction

" }}}1

" Utility functions
function! s:root() abort " {{{1
  return get(g:, 'vimtex_cache_root',
        \ (empty($XDG_CACHE_HOME) ? $HOME . '/.cache' : $XDG_CACHE_HOME)
        \ . '/vimtex')
endfunction

" }}}1
function! s:local_name(name) abort " {{{1
  let l:filename = exists('b:vimtex.tex')
        \ ? fnamemodify(b:vimtex.tex, ':r')
        \ : expand('%:p:r')
  let l:filename = substitute(l:filename, '\s\+', '_', 'g')
  let l:filename = substitute(l:filename, '\/', '%', 'g')
  let l:filename = substitute(l:filename, '\\', '%', 'g')
  let l:filename = substitute(l:filename, ':', '%', 'g')
  return a:name . l:filename
endfunction

" }}}1


let s:_version = 'cache_v2'
