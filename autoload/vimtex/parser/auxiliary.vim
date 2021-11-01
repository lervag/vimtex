" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#auxiliary#parse(file) abort " {{{1
  return s:parse_recurse(a:file, [])
endfunction

" }}}1
function! vimtex#parser#auxiliary#labels() abort " {{{1
  "
  " Searches aux files recursively for commands of the form
  "
  "   \newlabel{name}{{number}{page}.*}.*
  "   \newlabel{name}{{text {number}}{page}.*}.*
  "   \newlabel{name}{{number}{page}{...}{type}.*}.*
  "
  " Returns a list of candidates like {'word': name, 'menu': type number page}.
  "
  let l:files = [[b:vimtex.aux(), '']]

  " Handle local file editing (e.g. subfiles package)
  if exists('b:vimtex_local') && b:vimtex_local.active
    let l:files += [[vimtex#state#get(b:vimtex_local.main_id).aux(), '']]
  endif

  " Add externaldocuments (from \externaldocument in preamble)
  let l:files += map(
        \ vimtex#parser#get_externalfiles(),
        \ '[v:val.aux, v:val.opt]')

  let l:cache = vimtex#cache#open('refcomplete', {
        \ 'local': 1,
        \ 'default': {'labels': [], 'ftime': -1}
        \})

  let l:labels = []
  for [l:file, l:prefix] in filter(l:files, 'filereadable(v:val[0])')
    let l:current = l:cache.get(l:file)
    let l:ftime = getftime(l:file)
    if l:ftime > l:current.ftime
      let l:current.ftime = l:ftime
      let l:current.labels = s:parse_labels(l:file, l:prefix)
      let l:cache.modified = 1
    endif

    let l:labels += l:current.labels
  endfor

  " Write cache to file
  call l:cache.write()

  return l:labels
endfunction

" }}}1

function! s:parse_recurse(file, parsed) abort " {{{1
  if !filereadable(a:file) || index(a:parsed, a:file) >= 0
    return []
  endif
  call add(a:parsed, a:file)

  let l:lines = []
  for l:line in readfile(a:file)
    call add(l:lines, l:line)

    if l:line =~# '\\@input{'
      let l:file = s:input_line_parser(l:line, a:file)
      call extend(l:lines, s:parse_recurse(l:file, a:parsed))
    endif
  endfor

  return l:lines
endfunction

" }}}1
function! s:input_line_parser(line, file) abort " {{{1
  let l:file = matchstr(a:line, '\\@input{\zs[^}]\+\ze}')

  " Remove extension to simplify the parsing (e.g. for "my file name".aux)
  let l:file = substitute(l:file, '\.aux', '', '')

  " Trim whitespaces and quotes from beginning/end of string, append extension
  let l:file = substitute(l:file, '^\(\s\|"\)*', '', '')
  let l:file = substitute(l:file, '\(\s\|"\)*$', '', '')
  let l:file .= '.aux'

  " Use absolute paths
  if l:file !~# '\v^(\/|[A-Z]:)'
    let l:file = fnamemodify(a:file, ':p:h') . '/' . l:file
  endif

  " Only return filename if it is readable
  return filereadable(l:file) ? l:file : ''
endfunction

" }}}1

function! s:parse_labels(file, prefix) abort " {{{1
  " Get lines from aux files
  let l:lines = vimtex#parser#auxiliary(a:file)
  let l:lines = filter(l:lines, 'v:val =~# ''\\newlabel{''')
  let l:lines = filter(l:lines, 'v:val !~# ''@cref''')
  let l:lines = filter(l:lines, 'v:val !~# ''sub@''')
  let l:lines = filter(l:lines, 'v:val !~# ''tocindent-\?[0-9]''')

  " Parse labels from lines
  let l:labels = []
  for l:line in l:lines
    let l:line = vimtex#util#tex2unicode(l:line)
    let l:tree = vimtex#util#tex2tree(l:line)[1:]
    let l:name = get(remove(l:tree, 0), 0, '')
    if empty(l:name) | continue | endif

    let l:name = a:prefix . l:name
    let l:context = remove(l:tree, 0)
    if type(l:context) == v:t_list && len(l:context) > 1
      let l:menu = ''
      try
        let l:type = substitute(l:context[3][0], '\..*$', ' ', '')
        let l:type = substitute(l:type, 'AMS', 'Equation', '')
        let l:menu .= toupper(l:type[0]) . l:type[1:]
      catch
      endtry

      let l:number = s:parse_number(l:context[0])
      if l:menu =~# 'Equation'
        let l:number = '(' . l:number . ')'
      endif
      let l:menu .= l:number

      try
        let l:menu .= ' [p. ' . l:context[1][0] . ']'
      catch
      endtry
      call add(l:labels, {'word': l:name, 'menu': l:menu})
    endif
  endfor

  return l:labels
endfunction

" }}}1
function! s:parse_number(num_tree) abort " {{{1
  if type(a:num_tree) == v:t_list
    if len(a:num_tree) == 0
      return '-'
    else
      let l:index = len(a:num_tree) == 1 ? 0 : 1
      return s:parse_number(a:num_tree[l:index])
    endif
  else
    let l:matches = matchlist(a:num_tree, '\v(^|.*\s)((\u|\d+)(\.\d+)*\l?)($|\s.*)')
    return len(l:matches) > 3 ? l:matches[2] : '-'
  endif
endfunction

" }}}1
