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
      \ {'title': 'Preamble',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/main.tex',
      \  'rank': 1, 'line': 1, 'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: /home/lervag/.local/plugged/vim...est/test-toc/./chapters/preamble.tex',
      \  'file': './chapters/preamble.tex',
      \  'rank': 5, 'line': 1, 'level': 0, 'type': 'include'},
      \ {'title': 'tex incl: /home/lervag/.local/plugged/vim.../test/test-toc/chapters/imported.tex',
      \  'file': 'chapters/imported.tex',
      \  'rank': 6, 'line': 1, 'level': 0, 'type': 'include'},
      \ {'title': 'bib incl: main.bib',
      \  'file': 'main.bib',
      \  'rank': 8, 'line': 1, 'level': 0, 'type': 'include', 'link': 1},
      \ {'title': 'Chapter in main',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/main.tex',
      \  'rank': 16, 'line': 14, 'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: /home/lervag/.local/plugged/vimtex/test/test-toc/chapters/subfile.tex',
      \  'file': 'chapters/subfile.tex',
      \  'rank': 17, 'line': 1, 'level': 0, 'type': 'include'},
      \ {'title': 'Subfile chapter',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/chapters/subfile.tex',
      \  'rank': 21, 'line': 4, 'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: /home/lervag/.local/plugged/vim...test-toc/chapters/sections/first.tex',
      \  'file': 'chapters/sections/first.tex',
      \  'rank': 24, 'line': 1, 'level': 0, 'type': 'include'},
      \ {'title': 'The first section',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/chapters/sections/first.tex',
      \  'rank': 28, 'line': 4, 'level': 1, 'type': 'content'},
      \ {'title': 'A subsection',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/chapters/sections/first.tex',
      \  'rank': 31, 'line': 7, 'level': 2, 'type': 'content'},
      \ {'title': 'tex incl: /home/lervag/.local/plugged/vim...est-toc/chapters/sections/second.tex',
      \  'file': 'chapters/sections/second.tex',
      \  'rank': 35, 'line': 1, 'level': 2, 'type': 'include'},
      \ {'title': 'The second section',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/chapters/sections/second.tex',
      \  'rank': 38, 'line': 3, 'level': 1, 'type': 'content'},
      \ {'title': 'My Custom Environment',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/main.tex',
      \  'rank': 44, 'line': 17, 'level': 0, 'type': 'content'},
      \ {'title': 'tex incl: /home/lervag/.local/plugged/vim...test/test-toc/./chapters/chapter.tex',
      \  'file': './chapters/chapter.tex',
      \  'rank': 48, 'line': 1, 'level': 1, 'type': 'include'},
      \ {'title': 'Some chapter',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/./chapters/chapter.tex',
      \  'rank': 49, 'line': 1, 'level': 0, 'type': 'content'},
      \ {'title': '$L^p$ spaces',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/./chapters/chapter.tex',
      \  'rank': 52, 'line': 4, 'level': 1, 'type': 'content'},
      \ {'title': 'tex incl: /home/lervag/.local/plugged/vim...st/test-toc/./chapters/equations.tex',
      \  'file': './chapters/equations.tex',
      \  'rank': 56, 'line': 1, 'level': 1, 'type': 'include'},
      \ {'title': 'Chapter with equations',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/./chapters/equations.tex',
      \  'rank': 57, 'line': 1, 'level': 0, 'type': 'content'},
      \ {'title': 'chap:chapter_1                (4 [p. 9])',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/./chapters/equations.tex',
      \  'rank': 58, 'line': 2, 'level': 0, 'type': 'label'},
      \ {'title': 'eq:1                        (4.1 [p. 9])',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/./chapters/equations.tex',
      \  'rank': 63, 'line': 7, 'level': 0, 'type': 'label'},
      \ {'title': 'eq:2                        (4.2 [p. 9])',
      \  'file': '/home/lervag/.local/plugged/vimtex/test/test-toc/./chapters/equations.tex',
      \  'rank': 70, 'line': 14, 'level': 0, 'type': 'label'},
      \]
  for s:key in ['title', 'file', 'rank', 'line', 'level', 'type']
    call assert_equal(s:expect[s:key], s:toc[s:n][s:key], 'Failed at index ' . s:n)
  endfor
  let s:n += 1
endfor

call assert_equal(s:n, len(s:toc))

call vimtex#test#finished()
