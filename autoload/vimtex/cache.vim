" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#cache#open(name) abort " {{{1
  let s:caches = get(s:, 'caches', {})
  if has_key(s:caches, a:name)
    return s:caches[a:name]
  endif

  let l:cache_root = get(g:, 'vimtex_cache_root', $HOME . '/.cache/vimtex')
  if !isdirectory(l:cache_root)
    call mkdir(l:cache_root, 'p')
  endif

  let l:path = l:cache_root . '/' . a:name . '.json'

  let l:cache = deepcopy(s:cache)
  call l:cache.init(l:path)
  unlet l:cache.init

  let s:caches[a:name] = l:cache

  return l:cache
endfunction

" }}}1
function! vimtex#cache#wrap(Func, name) abort " {{{1
  let l:cache = vimtex#cache#open(a:name)

  function! CachedFunc(key) closure
    if l:cache.has(a:key)
      return l:cache.get(a:key)
    else
      return l:cache.insert(a:key, a:Func(a:key))
    endif
  endfunction

  return function('CachedFunc')
endfunction

" }}}1
function! vimtex#cache#write_all() abort " {{{1
  for l:cache in values(get(s:, 'caches', {}))
    call l:cache.write()
  endfor
endfunction

" }}}1

let s:cache = {}

function! s:cache.init(path) abort " {{{1
  let self.path = a:path
  let self.data = {}
  let self.ftime = -1
endfunction

" }}}1

function! s:cache.get(key) abort " {{{1
  call self.read()

  return get(self.data, a:key)
endfunction

" }}}1
function! s:cache.has(key) abort " {{{1
  call self.read()

  return has_key(self.data, a:key)
endfunction

" }}}1
function! s:cache.insert(key, value) abort " {{{1
  call self.read()

  if has_key(self.data, a:key)
    throw 'vimtex#cache: Key already exists: ' . a:key
  endif

  let self.data[a:key] = a:value

  if localtime() > self.ftime + 299
    call s:cache.write()
  endif

  return a:value
endfunction

" }}}1
function! s:cache.update(key, value) abort " {{{1
  call self.read()

  if !has_key(self.data, a:key)
    throw 'vimtex#cache: Key does not exists: ' . a:key
  endif

  let self.data[a:key] = a:value

  if localtime() > self.ftime + 299
    call s:cache.write()
  endif

  return a:value
endfunction

" }}}1

function! s:cache.write() abort " {{{1
  call self.read()

  call writefile([json_encode(self.data)], self.path)

  let self.ftime = getftime(self.path)
endfunction

" }}}1
function! s:cache.read() abort " {{{1
  if getftime(self.path) > self.ftime
    let self.ftime = getftime(self.path)
    call extend(self.data, json_decode(readfile(self.path)), 'keep')
  else
    let self.ftime = localtime()
  endif
endfunction

" }}}1
