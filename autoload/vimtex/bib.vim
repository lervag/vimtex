" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#bib#files() abort " {{{1
  if has_key(b:vimtex.packages, 'biblatex')
    let l:file = b:vimtex.ext('bcf')
    if filereadable(l:file)
      let l:bibs = map(
            \ filter(readfile(l:file), "v:val =~# 'bcf:datasource'"),
            \ {_, x -> matchstr(x, '<[^>]*>\zs[^<]*')})
      for l:f in filter(copy(l:bibs), {_, x -> x =~# '[*?{[]' })
        let l:bibs += glob(l:f, 0, 1)
      endfor
      if !empty(l:bibs) | return s:validate(l:bibs) | endif
    endif
  endif

  let l:file = b:vimtex.ext('blg')
  if filereadable(l:file)
    let l:bibs = map(
          \ filter(readfile(l:file), 'v:val =~# ''^Database file #\d'''),
          \ {_, x -> matchstr(x, '#\d\+: \zs.*\ze\.bib$')})

    " Ignore '{name}-blx.bib' file (created by biblatex)
    if has_key(b:vimtex.packages, 'biblatex')
      call filter(l:bibs, 'v:val !~# ''-blx$''')
    endif

    " Ignore '{name}Notes.bib' file (created by revtex4)
    if b:vimtex.documentclass =~# '^revtex4'
      call filter(l:bibs, 'v:val !~# ''.Notes$''')
    endif

    if !empty(l:bibs) | return s:validate(l:bibs) | endif
  endif

  return s:validate(s:files_manual())
endfunction

" }}}1

function! s:validate(files) abort " {{{1
  call filter(a:files, {_, x -> !empty(x)})
  call map(a:files, {_, x -> substitute(x, '\%(\.bib\)\?$', '.bib', '')})
  call map(a:files, {_, x -> filereadable(x) ? x : vimtex#kpsewhich#find(x)})
  call filter(a:files, {_, x -> filereadable(x)})

  return a:files
endfunction

" }}}1
function! s:files_manual() abort " {{{1
  "
  " Search for bibliography files by parsing the source code
  " * Parse commands such as \bibliography{file1,file2.bib,...}
  "

  let l:cache = vimtex#cache#open('bibfiles', {
        \ 'local': 1,
        \ 'default': {'files': [], 'ftime': -1}
        \})

  " Handle local file editing (e.g. subfiles package)
  let l:id = get(get(b:, 'vimtex_local', {'main_id' : b:vimtex_id}), 'main_id')
  let l:vimtex = vimtex#state#get(l:id)

  let l:bibfiles = []
  for l:file in map(copy(l:vimtex.sources), 'l:vimtex.root . ''/'' . v:val')
    let l:current = l:cache.get(l:file)

    let l:ftime = getftime(l:file)
    if l:ftime > l:current.ftime
      let l:cache.modified = 1
      let l:current.ftime = l:ftime
      let l:current.files = []

      for l:entry in map(
            \ filter(readfile(l:file), {_, x -> x =~# s:bib_re}),
            \ {_, x -> matchstr(x, s:bib_re)})
        " Interpolate the \jobname command
        let l:entry = substitute(l:entry, '\\jobname', b:vimtex.name, 'g')

        " Assume comma separated list of files
        let l:files = split(l:entry, ',')

        " But also add the unmodified entry for consideration, as the comma may
        " be part of the filename or part of a globbing expression.
        if len(l:files) > 1
          let l:files += [l:entry]
        endif

        " Now attempt to apply globbing where applicable
        for l:exp in filter(copy(l:files), {_, x -> x =~# '[*?{[]'})
          try
            let l:globbed = glob(l:exp, 0, 1)
            let l:files += l:globbed
          catch /E220/
          endtry
        endfor

        let l:current.files += l:files
      endfor
    endif

    let l:bibfiles += l:current.files
  endfor

  " Write cache to file
  call l:cache.write()

  return uniq(l:bibfiles)
endfunction

" }}}1

let s:bib_re = g:vimtex#re#not_comment . '\\('
      \ . join(g:vimtex_bibliography_commands, '|')
      \ . ')\s*\{\zs.+\ze}'
