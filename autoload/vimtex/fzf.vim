" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#fzf#run(...) abort " {{{1
  " Arguments: Two optional arguments
  "
  " First argument: ToC filter (default: 'ctli')
  "   This may be used to select certain entry types according to the different
  "   "layers" of vimtex-toc:
  "     c:  content: This is the main part and the "real" ToC
  "     t:  todo: This shows TODOs from comments and `\todo{...}` commands
  "     l:  label: This shows `\label{...}` commands
  "     i:  include: This shows included files
  "
  " Second argument: Custom options for fzf
  "   It should be an object containing the parameters passed to fzf#run().

  " Note: The '--with-nth 3..' option hides the first two words from the fzf
  "       window. These words are the file name and line number and are used by
  "       the sink.
  let l:opts = extend({
      \ 'source': <sid>parse_toc(a:0 == 0 ? 'ctli' : a:1),
      \ 'sink': function('vimtex#fzf#open_selection'),
      \ 'options': '--ansi --with-nth 3..',
      \}, a:0 > 1 ? a:2 : {})

  call fzf#run(l:opts)
endfunction

" }}}1
function! vimtex#fzf#open_selection(sel) abort " {{{1
  let line = split(a:sel)[0]
  let file = split(a:sel)[1]
  let curr_file = expand('%:p')

  if curr_file == file
    execute 'normal! ' . line . 'gg'
  else
    execute printf('edit +%s %s', line, file)
  endif
endfunction

" }}}1


function! s:parse_toc(filter) abort " {{{1
  " Parsing is mostly adapted from the Denite source
  " (see rplugin/python3/denite/source/vimtex.py)
  python3 << EOF
import vim
import json

def format_number(n):
  if not n or not type(n) is dict or not 'chapter' in n:
      return ''

  num = [str(n[k]) for k in [
         'chapter',
         'section',
         'subsection',
         'subsubsection',
         'subsubsubsection'] if n[k] != '0']

  if n['appendix'] != '0':
     num[0] = chr(int(num[0]) + 64)

  return '.'.join(num)

def colorize(e):
  try:
    from colorama import Fore, Style
    color = {'content' : Fore.WHITE,
             'include' : Fore.BLUE,
             'label' : Fore.GREEN,
             'todo' : Fore.RED}[e['type']]
    return f"{color}{e['title']:65}{Style.RESET_ALL}"
  except ModuleNotFoundError:
    import os
    if os.name  == 'nt':
      # Colour support on Windows requires Colorama
      return f"{e['title']:65}"
    else:
      color = {'content' : "\u001b[37m",
               'include' : "\u001b[34m",
               'label' : "\u001b[32m",
               'todo' : "\u001b[31m"}[e['type']]
      return f"{color}{e['title']:65}\u001b[0m"

def create_candidate(e, depth):
  number = format_number(dict(e['number']))
  return f"{e.get('line', 0)} {e['file']} {colorize(e)} {number}"

entries = vim.eval('vimtex#parser#toc()')
depth = max([int(e['level']) for e in entries])
filter = vim.eval("a:filter")
candidates = [create_candidate(e, depth)
              for e in entries if e['type'][0] in filter]

# json.dumps will convert single quotes to double quotes
# so that vim understands the ansi escape sequences
vim.command(f"let candidates = {json.dumps(candidates)}")
EOF

  return candidates
endfunction

" }}}1
