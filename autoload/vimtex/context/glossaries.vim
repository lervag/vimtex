" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#context#glossaries#new() abort " {{{1
  return deepcopy(s:handler)
endfunction

" }}}1

let s:handler = {
      \ 'name': 'glossaries handler',
      \}
function! s:handler.match(cmd, word) abort dict " {{{1
  if empty(a:cmd)
        \ || a:cmd.name[1:] !~# '\v([cpdr]?(gls|Gls|GLS)|acr|Acr|ACR)\a*>'
        \ || len(a:cmd.args) != 1
    return v:false
  endif

  let l:keys = a:cmd.args->map({_, x -> x.text})->join(',')->split(',\s*')
  let self.selected = index(l:keys, a:word) >= 0 ? a:word : l:keys[0]

  return !empty(self.selected)
endfunction

" }}}1
function! s:handler.get_actions() abort dict " {{{1
  let l:entry = s:get_entry(self.selected)

  if empty(l:entry)
    call vimtex#log#warning('Glossary key not found: ' .. self.selected)
    return {}
  endif

  return s:actions.create(l:entry)
endfunction

" }}}1

let s:actions = {
      \ 'menu': [
      \   {'name': 'Go to entry',
      \    'func': 'goto'},
      \   {'name': 'Go to entry in split',
      \    'func': 'goto_split'},
      \   {'name': 'Show entry',
      \    'func': 'show'},
      \ ],
      \}
function! s:actions.create(entry) abort dict " {{{1
  let l:new = deepcopy(self)
  unlet l:new.create

  let l:new.entry = deepcopy(a:entry)
  let l:new.prompt = 'Context menu for glossary key: ' .. a:entry.key

  return l:new
endfunction

" }}}1
function! s:actions.show() abort dict " {{{1
  let l:entry = deepcopy(self.entry)

  call vimtex#ui#echo([
        \ ['Normal', '@'],
        \ ['VimtexMsg', l:entry.type],
        \ ['Normal', '{'],
        \ ['Special', l:entry.key],
        \ ['Normal', ','],
        \])

  for l:x in ['key', 'type', 'source_lnum', 'source_file']
    if has_key(l:entry, l:x)
      call remove(l:entry, l:x)
    endif
  endfor

  for l:x in ['title', 'author', 'year']
    if has_key(l:entry, l:x)
      call vimtex#ui#echo([
            \ ['VimtexInfoValue', '  ' .. l:x .. ': '],
            \ ['Normal', remove(l:entry, l:x)]
            \])
    endif
  endfor

  for [l:key, l:val] in items(l:entry)
      call vimtex#ui#echo([
            \ ['VimtexInfoValue', '  ' .. l:key .. ': '],
            \ ['Normal', l:val]
            \])
  endfor
  call vimtex#ui#echo([['Normal', '}']])
endfunction

" }}}1
function! s:actions.goto() abort dict " {{{1
  execute 'edit' self.entry.source_file
  filetype detect

  call vimtex#pos#set_cursor(self.entry.source_lnum, 0)
  normal! zv
endfunction

" }}}1
function! s:actions.goto_split() abort dict " {{{1
  execute 'split' self.entry.source_file
  filetype detect

  call vimtex#pos#set_cursor(self.entry.source_lnum, 0)
  normal! zv
endfunction

" }}}1

function! s:get_entry(key) abort " {{{1
  " Ensure we're at the root directory when locating bib files
  call vimtex#paths#pushd(b:vimtex.root)
  let l:entries = []
  for l:file in b:vimtex.glossaries
    let l:entries += vimtex#parser#bib(
          \ l:file,
          \ {'backend': has('nvim') ? 'lua' : 'vim'}
          \)
  endfor
  call vimtex#paths#popd()

  " Return entry with the given key
  return l:entries->filter({_, x -> x.key ==# a:key})->get(0, {})
endfunction

" }}}1
