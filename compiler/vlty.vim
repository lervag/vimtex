if exists('current_compiler') | finish | endif
let current_compiler = 'vlty'

let s:cpo_save = &cpo
set cpo&vim

let s:python = executable('python3') ? 'python3' : 'python'
let s:vlty = g:vimtex_grammar_vlty

function! s:installation_error(msg)
  call vimtex#log#error(
        \ [a:msg, 'Please see ":help vimtex-grammar-vlty" for more details.'])
endfunction

if !executable(s:python)
  call s:installation_error('vlty compiler requires Python')
  finish
endif

call system(s:python . ' -c "import sys; assert sys.version_info >= (3, 6)"')
if v:shell_error != 0
  call s:installation_error('vlty compiler requires at least Python version 3.6')
  finish
endif

call system(s:python . ' -c "import yalafi"')
if v:shell_error != 0
  call s:installation_error('vlty compiler requires the Python module YaLafi')
  finish
endif

if s:vlty.server !=# 'lt'
  if !executable('java')
    call s:installation_error('vlty compiler requires java')
    finish
  endif

  if !empty(s:vlty.lt_command)
    if !executable(s:vlty.lt_command)
      call s:installation_error('vlty compiler - lt_command not valid')
      finish
    endif
  elseif !filereadable(fnamemodify(s:vlty.lt_directory
        \ . '/languagetool-commandline.jar', ':p'))
    call s:installation_error('vlty compiler - lt_directory path not valid')
    finish
  endif
endif

let s:vimtex = get(b:, 'vimtex', {'documentclass': '', 'packages': {}})
let s:documentclass = s:vimtex.documentclass
let s:packages = join(keys(s:vimtex.packages), ',')
let s:language = vimtex#ui#choose(split(&spelllang, ','), {
      \ 'prompt': 'Multiple spelllang languages detected, please select one:',
      \ 'abort': v:false,
      \})
let s:language = substitute(s:language, '_', '-', '')

let &l:makeprg =
      \ s:python . ' -m yalafi.shell'
      \ . (!empty(s:vlty.lt_command)
      \    ? ' --lt-command ' . s:vlty.lt_command
      \    : ' --lt-directory ' . s:vlty.lt_directory)
      \ . (s:vlty.server ==# 'no'
      \    ? ''
      \    : ' --server ' . s:vlty.server)
      \ . ' --encoding ' . (s:vlty.encoding ==# 'auto'
      \    ? (empty(&l:fileencoding) ? &l:encoding : &l:fileencoding)
      \    : s:vlty.encoding)
      \ . ' --language ' . s:language
      \ . ' --disable "' . s:vlty.lt_disable . '"'
      \ . ' --enable "' . s:vlty.lt_enable . '"'
      \ . ' --disablecategories "' . s:vlty.lt_disablecategories . '"'
      \ . ' --enablecategories "' . s:vlty.lt_enablecategories . '"'
      \ . ' --documentclass "' . s:documentclass . '"'
      \ . ' --packages "' . s:packages . '"'
      \ . ' ' . s:vlty.shell_options
      \ . ' %:S'
silent CompilerSet makeprg

let &l:errorformat = '%I=== %f ===,%C%*\d.) Line %l\, column %v\, Rule ID:%.%#'

let &l:errorformat .= s:vlty.show_suggestions
      \ ? ',%CMessage: %m,%Z%m'
      \ : ',%ZMessage: %m'

" For compatibility with vim-dispatch we need duplicated '%-G%.%#'.
" See issues #199 of vim-dispatch and #1854 of VimTeX.
let &l:errorformat .= ',%-G%.%#,%-G%.%#'

silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
