" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#cache#open(name, ...) abort " {{{1
  let s:caches = get(s:, 'caches', {})
  if has_key(s:caches, a:name)
    return s:caches[a:name]
  endif

  let l:cache_root = get(g:, 'vimtex_cache_root', $HOME . '/.cache/vimtex')
  if !isdirectory(l:cache_root)
    call mkdir(l:cache_root, 'p')
  endif

  let l:opts = {
        \ 'path': l:cache_root . '/' . a:name . '.json',
        \ 'persistent': get(g:, 'vimtex_cache_persistant', 1),
        \}
  if a:0 > 0 | call extend(l:opts, a:1) | endif

  let s:caches[a:name] = s:cache.init(l:opts)
  return s:caches[a:name]
endfunction

" }}}1
function! vimtex#cache#close(name) abort " {{{1
  let s:caches = get(s:, 'caches', {})
  if !has_key(s:caches, a:name) | return | endif

  let l:cache = s:caches[a:name]
  call l:cache.write()
  unlet s:caches[a:name]
endfunction

" }}}1
function! vimtex#cache#wrap(Func, name, ...) abort " {{{1
  let l:cache = vimtex#cache#open(a:name, a:0 > 0 ? a:1 : {})

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
function! vimtex#cache#clear(name) abort " {{{1
  let l:cache = vimtex#cache#open(a:name)

  call l:cache.read()
  let l:cache.data = {}
  call l:cache.write()
endfunction

" }}}1
function! vimtex#cache#write_all() abort " {{{1
  for l:cache in values(get(s:, 'caches', {}))
    call l:cache.write()
  endfor
endfunction

" }}}1

let s:cache = {}

function! s:cache.init(opts) dict abort " {{{1
  let new = deepcopy(self)
  unlet new.init

  let new.path = a:opts.path
  let new.persistent = a:opts.persistent
  let new.data = {}
  let new.ftime = -1

  return new
endfunction

" }}}1
function! s:cache.get(key) dict abort " {{{1
  call self.read()

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

  if localtime() > self.ftime + 299
    call self.write()
  endif

  return a:value
endfunction

" }}}1
function! s:cache.write() dict abort " {{{1
  if !self.persistent | return | endif

  call self.read()

  call writefile([json_encode(self.data)], self.path)

  let self.ftime = getftime(self.path)
endfunction

" }}}1
function! s:cache.read() dict abort " {{{1
  if !self.persistent | return | endif

  if getftime(self.path) > self.ftime
    let self.ftime = getftime(self.path)
    call extend(self.data,
          \ json_decode(join(readfile(self.path))), 'keep')
  else
    let self.ftime = localtime()
  endif
endfunction

" }}}1
