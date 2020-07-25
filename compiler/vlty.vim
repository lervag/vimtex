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

  if !filereadable(fnamemodify(s:vlty.lt_directory
        \ . '/languagetool-commandline.jar', ':p'))
    call s:installation_error('vlty compiler - lt_directory path not valid')
    finish
  endif
endif

let s:vimtex = get(b:, 'vimtex', {'documentclass': '', 'packages': {}})
let s:documentclass = s:vimtex.documentclass
let s:packages = join(keys(s:vimtex.packages), ',')
let s:language = matchstr(&spelllang, '\v^\a\a([-_]\a\a)?')
let s:language = substitute(s:language, '_', '-', '')

let &l:makeprg =
      \ s:python . ' -m yalafi.shell'
      \ . ' --lt-directory ' . s:vlty.lt_directory
      \ . (s:vlty.server ==# 'no'
      \    ?  ''
      \    : ' --server ' . s:vlty.server)
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

let &l:errorformat = '%I=== %f ===,%C%*\d.) Line %l\, column %v\, Rule ID:%.%#,'
if s:vlty.show_suggestions == 0
  let &l:errorformat .= '%ZMessage: %m,%-G%.%#'
else
  let &l:errorformat .= '%CMessage: %m,%Z%m,%-G%.%#'
endif
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
