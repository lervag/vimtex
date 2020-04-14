" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#cache#open(name, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}
  let l:name = get(l:opts, 'local') ? s:local_name(a:name) : a:name

  let s:caches = get(s:, 'caches', {})
  if has_key(s:caches, l:name)
    return s:caches[l:name]
  endif

  let s:caches[l:name] = s:cache.init(l:name, l:opts)
  return s:caches[l:name]
endfunction

" }}}1
function! vimtex#cache#close(name) abort " {{{1
  let s:caches = get(s:, 'caches', {})

  " Try global name first, then local name
  let l:name = a:name
  if !has_key(s:caches, l:name)
    let l:name = s:local_name(l:name)
  endif
  if !has_key(s:caches, l:name) | return | endif

  let l:cache = s:caches[l:name]
  call l:cache.write()
  unlet s:caches[l:name]
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
function! vimtex#cache#clear(name, local) abort " {{{1
  let l:cache = vimtex#cache#open(a:name, {'local': a:local})

  call l:cache.read()
  if !empty(l:cache.data)
    let l:cache.data = {}
    call l:cache.write()
  endif
endfunction

" }}}1
function! vimtex#cache#write_all() abort " {{{1
  for l:cache in values(get(s:, 'caches', {}))
    call l:cache.write()
  endfor
endfunction

" }}}1

let s:cache = {}

function! s:cache.init(name, opts) dict abort " {{{1
  let new = deepcopy(self)
  unlet new.init

  let l:root = get(g:, 'vimtex_cache_root', $HOME . '/.cache/vimtex')
  if !isdirectory(l:root)
    call mkdir(l:root, 'p')
  endif

  let new.name = a:name
  let new.path = l:root . '/' . a:name . '.json'
  let new.local = get(a:opts, 'local')
  let new.persistent = get(a:opts, 'persistent',
        \ get(g:, 'vimtex_cache_persistent', 1))

  if has_key(a:opts, 'default')
    let new.default = a:opts.default
  endif

  let new.data = {}
  let new.ftime = -1
  let new.modified = 0

  return new
endfunction

" }}}1
function! s:cache.get(key) dict abort " {{{1
  call self.read()

  if has_key(self, 'default') && !has_key(self.data, a:key)
    let self.data[a:key] = deepcopy(self.default)
  endif

  return get(self.data, a:key)
endfunction

" }}}1
function! s:cache.has(key) dict abort " {{{1
  call self.read()

  return has_key(self.data, a:key)
endfunction

" }}}1
function! s:cache.set(key, value) dict abort " {{{1
  call self.read()

  let self.data[a:key] = a:value
  let self.modified = 1
  call self.write()

  return a:value
endfunction

" }}}1
function! s:cache.write() dict abort " {{{1
  if !self.persistent
    let self.modified = 0
    return
  endif

  if !self.modified | return | endif

  call self.read()
  call writefile([json_encode(self.data)], self.path)
  let self.ftime = getftime(self.path)
  let self.modified = 0
endfunction

" }}}1
function! s:cache.read() dict abort " {{{1
  if !self.persistent | return | endif

  if getftime(self.path) > self.ftime
    let self.ftime = getftime(self.path)
    call extend(self.data,
          \ json_decode(join(readfile(self.path))), 'keep')
  endif
endfunction

" }}}1

"
" Utility functions
"
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
