" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fold#bib#init() abort " {{{1
  let b:vimtex_fold_bib_maxwidth = s:get_max_key_width()

  augroup vimtex_buffers
    autocmd BufWrite <buffer>
          \ let b:vimtex_fold_bib_maxwidth = s:get_max_key_width()
  augroup END

  setlocal foldmethod=expr
  setlocal foldexpr=vimtex#fold#bib#level(v:lnum)
  setlocal foldtext=vimtex#fold#bib#text()
endfunction

" }}}1

function! vimtex#fold#bib#level(lnum) abort " {{{1
  " Handle blank lines
  if empty(trim(getline(a:lnum)))
    if a:lnum == 1 | return 0 | endif

    let l:prev_level = vimtex#fold#bib#level(a:lnum - 1)
    return l:prev_level == '<1' ? 0 : l:prev_level
  endif

  " Search for the beginning of the entry
  let l:curpos = getcurpos()
  call cursor(a:lnum, 0)
  let l:firstline = search('\v^\s*\@', 'bcnW')
  call setpos('.', l:curpos)

  " Check if we're at fold start
  let l:text = join(getline(l:firstline, a:lnum))
  let l:count_open = s:count(l:text, '{')
  let l:braces_balanced = l:count_open == s:count(l:text, '}')
  if l:firstline == a:lnum
    return l:count_open > 0 && l:braces_balanced ? 0 : '>1'
  endif

  " Beginning of entry wasn't found
  if l:firstline == 0 | return 0 | endif

  " Check if braces are closed by the current line
  return l:braces_balanced ? '<1' : 1
endfunction

" }}}1
function! vimtex#fold#bib#text() abort " {{{1
  let l:bib_entries = vimtex#parser#bib#parse_cheap(v:foldstart, v:foldend, {})
  if len(l:bib_entries) != 1 | return foldtext() | endif

  let l:entry = l:bib_entries[0]
  if empty(l:entry.type) || empty(l:entry.key)
    return foldtext()
  endif

  let l:foldtext = '@' . l:entry.type . '{' . l:entry.key . '}'

  let l:width = strdisplaywidth(l:foldtext)
  if l:width > b:vimtex_fold_bib_maxwidth
    let l:foldtext = printf('%.' . b:vimtex_fold_bib_maxwidth . 'S', l:foldtext)
    let l:width = strdisplaywidth(l:foldtext)
  endif
  let l:desired_width = b:vimtex_fold_bib_maxwidth + 2
  let l:foldtext .= repeat(' ', l:desired_width - l:width)

  if has_key(l:entry, 'description') && !empty(l:entry.description)
    let l:foldtext .= l:entry.description
  endif

  return l:foldtext
endfunction

" }}}1

function! s:get_max_key_width() " {{{1
  if g:vimtex_fold_bib_max_key_width > 0
    return g:vimtex_fold_bib_max_key_width
  endif

  let l:entries = vimtex#parser#bib#parse_cheap(1, line('$'),
        \ {'get_description': v:false})
  if empty(l:entries) | return 32 | endif

  " Extra 3 is for the @ symbol plus curly braces.
  call map(l:entries, {_, e -> 3
        \ + strdisplaywidth(get(e, 'type', ''))
        \ + strdisplaywidth(get(e, 'key', ''))})

  return max(l:entries)
endfunction

" }}}1
function! s:count(container, item) abort " {{{1
  " Necessary because in old Vim versions, count() does not work for strings
  try
    let l:count = count(a:container, a:item)
  catch /E712/
    let l:count = count(split(a:container, '\zs'), a:item)
  endtry

  return l:count
endfunction

" }}}1
