if exists('current_compiler') | finish | endif
let current_compiler = 'vlty'

let s:cpo_save = &cpo
set cpo&vim
let s:pref = 'vlty compiler  - '
let s:python = executable('python3') ? 'python3' : 'python'
let s:vlty = g:vimtex_grammar_vlty

function! s:installation_error(msg)
  call vimtex#log#error(
        \ [a:msg, 'Please see ":help vimtex-grammar-vlty" for more details.'])
endfunction

if !executable(s:python)
  call s:installation_error(s:pref . 'requires Python')
  finish
endif

call system(s:python . ' -c "import sys; assert sys.version_info >= (3, 6)"')
if v:shell_error != 0
  call s:installation_error(s:pref . 'requires at least Python version 3.6')
  finish
endif

call system(s:python . ' -c "import yalafi"')
if v:shell_error != 0
  call s:installation_error(s:pref . 'requires the Python module YaLafi')
  finish
endif

if !exists('s:vlty.lt_command')
    let s:vlty.lt_command = ''
endif
let s:vlty_lt_command = ''
if s:vlty.server !=# 'lt'
    if !executable('java')
        echoerr s:pref . 'install Java.'
        finish
    endif
    if s:vlty.lt_command != ''
        if !executable(s:vlty.lt_command)
            echoerr s:pref . 'set s:vlty.lt_command correctly.'
            finish
        else
          let s:vlty_lt_command = s:vlty.lt_command
        endif
    else
        if !filereadable(fnamemodify(s:vlty.lt_directory . '/languagetool-commandline.jar', ':p'))
            echoerr s:pref . 'set s:vlty.lt_directory to the'
                        \ . ' path of LanguageTool.'
            finish
        else
            let s:vlty_lt_command = 'java -jar ' . fnamemodify(s:vlty.lt_directory . '/languagetool-commandline.jar', ':p:S')
        endif
    endif
endif

let s:vimtex = get(b:, 'vimtex', {'documentclass': '', 'packages': {}})
let s:documentclass = s:vimtex.documentclass
let s:packages = join(keys(s:vimtex.packages), ',')

" guess language
"
if !exists('s:vlty.language')
  let s:vlty.language = vimtex#ui#choose(split(&spelllang, ','), {
        \ 'prompt': 'Multiple spelllang languages detected, please select one:',
        \ 'abort': v:false,
        \})
  let s:vlty.language = substitute(s:vlty.language, '_', '-', '')
endif

if !exists('s:list')
    silent let s:list = split(system(s:vlty_lt_command . ' --list'), '[[:space:]]')
endif
if !empty(s:list)
    if match(s:list, '\c^' . s:vlty.language . '$') == -1
        echohl WarningMsg | echomsg "Language '" . s:vlty.language . "' not listed in output of " . s:vlty_lt_command . " --list!" | echohl None
        let s:vlty.language = matchstr(s:vlty.language, '\v^[^-]+')
        echohl WarningMsg | echomsg "Trying '" . s:vlty.language . "' instead." | echohl None
        if match(s:list, '\c^' . s:vlty.language . '$') == -1
            echoerr "Language '" . s:vlty.language . "' not listed in output of " . s:vlty_lt_command . " --list; trying anyway!"
        endif
    endif
endif
if empty(s:vlty.language)
    echohl WarningMsg | echomsg 'Please set g:vimtex_grammar_vlty.language for more accurate check by LanguageTool; using autodetection instead.' | echohl None
    let s:vlty_language = ' --autoDetect'
else
    let s:vlty_language = ' --language ' . s:vlty.language
endif

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
      \ . s:vlty_language
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
