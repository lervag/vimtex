set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

let g:vimtex_toc_custom_matchers = [
      \ { 'title' : 'My Custom Environment',
      \   're' : '\v^\s*\\begin\{quote\}' }
      \]

silent edit main.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()

let s:n = 0
for s:expect in [
      \ {'title': 'Preamble',                                 'rank': 1,  'line': 1,  'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: ./chapters/preamble.tex',        'rank': 5,  'line': 1,  'level': 0, 'type': 'include'},
      \ {'title': 'tex incl: chapters/imported.tex',          'rank': 6,  'line': 1,  'level': 0, 'type': 'include'},
      \ {'title': 'bib incl: main.bib',                       'rank': 8,  'line': 1,  'level': 0, 'type': 'include'},
      \ {'title': 'Chapter in main',                          'rank': 16, 'line': 14, 'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: chapters/subfile.tex',           'rank': 17, 'line': 1,  'level': 0, 'type': 'include'},
      \ {'title': 'Subfile chapter',                          'rank': 21, 'line': 4,  'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: chapters/sections/first.tex',    'rank': 24, 'line': 1,  'level': 0, 'type': 'include'},
      \ {'title': 'The first section',                        'rank': 28, 'line': 4,  'level': 1, 'type': 'content'},
      \ {'title': 'A subsection',                             'rank': 31, 'line': 7,  'level': 2, 'type': 'content'},
      \ {'title': 'tex incl: chapters/sections/second.tex',   'rank': 35, 'line': 1,  'level': 2, 'type': 'include'},
      \ {'title': 'The second section',                       'rank': 38, 'line': 3,  'level': 1, 'type': 'content'},
      \ {'title': 'My Custom Environment',                    'rank': 44, 'line': 17, 'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: ./chapters/chapter.tex',         'rank': 48, 'line': 1,  'level': 1, 'type': 'include'},
      \ {'title': 'Some chapter',                             'rank': 49, 'line': 1,  'level': 0, 'type': 'content'},
      \ {'title': '$L^p$ spaces',                             'rank': 52, 'line': 4,  'level': 1, 'type': 'content'},
      \ {'title': 'tex incl: ./chapters/equations.tex',       'rank': 56, 'line': 1,  'level': 1, 'type': 'include'},
      \ {'title': 'Chapter with equations',                   'rank': 57, 'line': 1,  'level': 0, 'type': 'content'},
      \ {'title': 'chap:chapter_1                (4 [p. 9])', 'rank': 58, 'line': 2,  'level': 0, 'type': 'label'},
      \ {'title': 'eq:1                        (4.1 [p. 9])', 'rank': 63, 'line': 7,  'level': 0, 'type': 'label'},
      \ {'title': 'eq:2                        (4.2 [p. 9])', 'rank': 70, 'line': 14, 'level': 0, 'type': 'label'},
      \]
  for s:key in ['title', 'rank', 'line', 'level', 'type']
    call assert_equal(s:expect[s:key], s:toc[s:n][s:key], 'Failed at index ' . s:n)
  endfor
  let s:n += 1
endfor

call assert_equal(s:n, len(s:toc))

call vimtex#test#finished()
