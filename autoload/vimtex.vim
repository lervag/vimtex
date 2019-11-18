" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#init() abort " {{{1
  call vimtex#init_options()

  call s:init_highlights()
  call s:init_state()
  call s:init_buffer()
  call s:init_default_mappings()

  if exists('#User#VimtexEventInitPost')
    doautocmd <nomodeline> User VimtexEventInitPost
  endif

  augroup vimtex_main
    autocmd!
    autocmd VimLeave * call s:quit()
  augroup END
endfunction

" }}}1
function! vimtex#init_options() abort " {{{1
  call s:init_option('vimtex_compiler_enabled', 1)
  call s:init_option('vimtex_compiler_method', 'latexmk')
  call s:init_option('vimtex_compiler_progname',
        \ get(v:, 'progpath', get(v:, 'progname')))
  call s:init_option('vimtex_compiler_callback_hooks', [])
  call s:init_option('vimtex_compiler_latexmk_engines', {})
  call s:init_option('vimtex_compiler_latexrun_engines', {})

  call s:init_option('vimtex_complete_enabled', 1)
  call s:init_option('vimtex_complete_close_braces', 0)
  call s:init_option('vimtex_complete_ignore_case', &ignorecase)
  call s:init_option('vimtex_complete_smart_case', &smartcase)
  call s:init_option('vimtex_complete_bib', {
        \ 'simple': 0,
        \ 'menu_fmt': '[@type] @author_short (@year), "@title"',
        \ 'abbr_fmt': '',
        \ 'custom_patterns': [],
        \})
  call s:init_option('vimtex_complete_ref', {
        \ 'custom_patterns': [],
        \})

  call s:init_option('vimtex_delim_timeout', 300)
  call s:init_option('vimtex_delim_insert_timeout', 60)
  call s:init_option('vimtex_delim_stopline', 500)

  call s:init_option('vimtex_include_search_enabled', 1)

  call s:init_option('vimtex_doc_enabled', 1)
  call s:init_option('vimtex_doc_handlers', [])

  call s:init_option('vimtex_echo_verbose_input', 1)

  call s:init_option('vimtex_env_change_autofill', 0)

  if &diff
    let g:vimtex_fold_enabled = 0
  else
    call s:init_option('vimtex_fold_enabled', 0)
  endif
  call s:init_option('vimtex_fold_manual', 0)
  call s:init_option('vimtex_fold_levelmarker', '*')
  call s:init_option('vimtex_fold_types', {})
  call s:init_option('vimtex_fold_types_defaults', {
        \ 'preamble' : {},
        \ 'comments' : { 'enabled' : 0 },
        \ 'envs' : {
        \   'blacklist' : [],
        \   'whitelist' : [],
        \ },
        \ 'env_options' : {},
        \ 'markers' : {},
        \ 'sections' : {
        \   'parse_levels' : 0,
        \   'sections' : [
        \     'part',
        \     'chapter',
        \     'section',
        \     'subsection',
        \     'subsubsection',
        \   ],
        \   'parts' : [
        \     'appendix',
        \     'frontmatter',
        \     'mainmatter',
        \     'backmatter',
        \   ],
        \ },
        \ 'cmd_single' : {
        \   'cmds' : [
        \     'hypersetup',
        \     'tikzset',
        \     'pgfplotstableread',
        \     'lstset',
        \   ],
        \ },
        \ 'cmd_single_opt' : {
        \   'cmds' : [
        \     'usepackage',
        \     'includepdf',
        \   ],
        \ },
        \ 'cmd_multi' : {
        \   'cmds' : [
        \     '%(re)?new%(command|environment)',
        \     'providecommand',
        \     'presetkeys',
        \     'Declare%(Multi|Auto)?CiteCommand',
        \     'Declare%(Index)?%(Field|List|Name)%(Format|Alias)',
        \   ],
        \ },
        \ 'cmd_addplot' : {
        \   'cmds' : [
        \     'addplot[+3]?',
        \   ],
        \ },
        \})

  call s:init_option('vimtex_format_enabled', 0)

  call s:init_option('vimtex_imaps_enabled', 1)
  call s:init_option('vimtex_imaps_disabled', [])
  call s:init_option('vimtex_imaps_list', [
        \ { 'lhs' : '0',  'rhs' : '\emptyset' },
        \ { 'lhs' : '6',  'rhs' : '\partial' },
        \ { 'lhs' : '8',  'rhs' : '\infty' },
        \ { 'lhs' : '=',  'rhs' : '\equiv' },
        \ { 'lhs' : '\',  'rhs' : '\setminus' },
        \ { 'lhs' : '.',  'rhs' : '\cdot' },
        \ { 'lhs' : '*',  'rhs' : '\times' },
        \ { 'lhs' : '<',  'rhs' : '\langle' },
        \ { 'lhs' : '>',  'rhs' : '\rangle' },
        \ { 'lhs' : 'H',  'rhs' : '\hbar' },
        \ { 'lhs' : '[',  'rhs' : '\subseteq' },
        \ { 'lhs' : ']',  'rhs' : '\supseteq' },
        \ { 'lhs' : '(',  'rhs' : '\subset' },
        \ { 'lhs' : ')',  'rhs' : '\supset' },
        \ { 'lhs' : 'A',  'rhs' : '\forall' },
        \ { 'lhs' : 'E',  'rhs' : '\exists' },
        \ { 'lhs' : 'jj', 'rhs' : '\downarrow' },
        \ { 'lhs' : 'jJ', 'rhs' : '\Downarrow' },
        \ { 'lhs' : 'jk', 'rhs' : '\uparrow' },
        \ { 'lhs' : 'jK', 'rhs' : '\Uparrow' },
        \ { 'lhs' : 'jh', 'rhs' : '\leftarrow' },
        \ { 'lhs' : 'jH', 'rhs' : '\Leftarrow' },
        \ { 'lhs' : 'jl', 'rhs' : '\rightarrow' },
        \ { 'lhs' : 'jL', 'rhs' : '\Rightarrow' },
        \ { 'lhs' : 'a',  'rhs' : '\alpha' },
        \ { 'lhs' : 'b',  'rhs' : '\beta' },
        \ { 'lhs' : 'c',  'rhs' : '\chi' },
        \ { 'lhs' : 'd',  'rhs' : '\delta' },
        \ { 'lhs' : 'e',  'rhs' : '\epsilon' },
        \ { 'lhs' : 'f',  'rhs' : '\phi' },
        \ { 'lhs' : 'g',  'rhs' : '\gamma' },
        \ { 'lhs' : 'h',  'rhs' : '\eta' },
        \ { 'lhs' : 'i',  'rhs' : '\iota' },
        \ { 'lhs' : 'k',  'rhs' : '\kappa' },
        \ { 'lhs' : 'l',  'rhs' : '\lambda' },
        \ { 'lhs' : 'm',  'rhs' : '\mu' },
        \ { 'lhs' : 'n',  'rhs' : '\nu' },
        \ { 'lhs' : 'p',  'rhs' : '\pi' },
        \ { 'lhs' : 'q',  'rhs' : '\theta' },
        \ { 'lhs' : 'r',  'rhs' : '\rho' },
        \ { 'lhs' : 's',  'rhs' : '\sigma' },
        \ { 'lhs' : 't',  'rhs' : '\tau' },
        \ { 'lhs' : 'y',  'rhs' : '\psi' },
        \ { 'lhs' : 'u',  'rhs' : '\upsilon' },
        \ { 'lhs' : 'w',  'rhs' : '\omega' },
        \ { 'lhs' : 'z',  'rhs' : '\zeta' },
        \ { 'lhs' : 'x',  'rhs' : '\xi' },
        \ { 'lhs' : 'G',  'rhs' : '\Gamma' },
        \ { 'lhs' : 'D',  'rhs' : '\Delta' },
        \ { 'lhs' : 'F',  'rhs' : '\Phi' },
        \ { 'lhs' : 'G',  'rhs' : '\Gamma' },
        \ { 'lhs' : 'L',  'rhs' : '\Lambda' },
        \ { 'lhs' : 'P',  'rhs' : '\Pi' },
        \ { 'lhs' : 'Q',  'rhs' : '\Theta' },
        \ { 'lhs' : 'S',  'rhs' : '\Sigma' },
        \ { 'lhs' : 'U',  'rhs' : '\Upsilon' },
        \ { 'lhs' : 'W',  'rhs' : '\Omega' },
        \ { 'lhs' : 'X',  'rhs' : '\Xi' },
        \ { 'lhs' : 'Y',  'rhs' : '\Psi' },
        \ { 'lhs' : 've', 'rhs' : '\varepsilon' },
        \ { 'lhs' : 'vf', 'rhs' : '\varphi' },
        \ { 'lhs' : 'vk', 'rhs' : '\varkappa' },
        \ { 'lhs' : 'vq', 'rhs' : '\vartheta' },
        \ { 'lhs' : 'vr', 'rhs' : '\varrho' },
        \])

  call s:init_option('vimtex_mappings_enabled', 1)
  call s:init_option('vimtex_mappings_disable', {})

  call s:init_option('vimtex_matchparen_enabled', 1)
  call s:init_option('vimtex_motion_enabled', 1)

  call s:init_option('vimtex_labels_enabled', 1)
  call s:init_option('vimtex_labels_refresh_always', 1)

  call s:init_option('vimtex_parser_bib_backend', 'bibtex')

  call s:init_option('vimtex_quickfix_enabled', 1)
  call s:init_option('vimtex_quickfix_method', 'latexlog')
  call s:init_option('vimtex_quickfix_autojump', '0')
  call s:init_option('vimtex_quickfix_mode', '2')
  call s:init_option('vimtex_quickfix_open_on_warning', '1')
  call s:init_option('vimtex_quickfix_blgparser', {})
  call s:init_option('vimtex_quickfix_autoclose_after_keystrokes', '0')

  call s:init_option('vimtex_syntax_enabled', 1)
  call s:init_option('vimtex_syntax_nested', {
        \ 'aliases' : {
        \   'C' : 'c',
        \   'csharp' : 'cs',
        \ },
        \ 'ignored' : {
        \   'cs' : [
        \     'csBraces',
        \   ],
        \   'python' : [
        \     'pythonEscape',
        \     'pythonBEscape',
        \     'pythonBytesEscape',
        \   ],
        \   'java' : [
        \     'javaError',
        \   ],
        \ }
        \})

  call s:init_option('vimtex_texcount_custom_arg', '')

  call s:init_option('vimtex_text_obj_enabled', 1)
  call s:init_option('vimtex_text_obj_variant', 'auto')
  call s:init_option('vimtex_text_obj_linewise_operators', ['d', 'y'])

  call s:init_option('vimtex_toc_enabled', 1)
  call s:init_option('vimtex_toc_custom_matchers', [])
  call s:init_option('vimtex_toc_show_preamble', 1)
  call s:init_option('vimtex_toc_todo_keywords', ['TODO', 'FIXME'])
  call s:init_option('vimtex_toc_config', {
        \ 'name' : 'Table of contents (vimtex)',
        \ 'mode' : 1,
        \ 'fold_enable' : 0,
        \ 'fold_level_start' : -1,
        \ 'hide_line_numbers' : 1,
        \ 'hotkeys_enabled' : 0,
        \ 'hotkeys' : 'abcdeilmnopuvxyz',
        \ 'hotkeys_leader' : ';',
        \ 'layer_status' : {
        \   'content': 1,
        \   'label': 1,
        \   'todo': 1,
        \   'include': 1,
        \ },
        \ 'layer_keys' : {
        \   'content': 'C',
        \   'label': 'L',
        \   'todo': 'T',
        \   'include': 'I',
        \ },
        \ 'resize' : 0,
        \ 'refresh_always' : 1,
        \ 'show_help' : 1,
        \ 'show_numbers' : 1,
        \ 'split_pos' : 'vert leftabove',
        \ 'split_width' : 30,
        \ 'tocdepth' : 3,
        \ 'todo_sorted' : 1,
        \})

  call s:init_option('vimtex_view_enabled', 1)
  call s:init_option('vimtex_view_automatic', 1)
  call s:init_option('vimtex_view_method', 'general')
  call s:init_option('vimtex_view_use_temp_files', 0)
  call s:init_option('vimtex_view_forward_search_on_start', 1)
  call s:init_option('vimtex_view_general_viewer', get({
        \ 'linux' : 'xdg-open',
        \ 'mac'   : 'open',
        \}, vimtex#util#get_os(), ''))
  call s:init_option('vimtex_view_general_options', '@pdf')
  call s:init_option('vimtex_view_general_options_latexmk', '')
  call s:init_option('vimtex_view_mupdf_options', '')
  call s:init_option('vimtex_view_mupdf_send_keys', '')
  call s:init_option('vimtex_view_skim_activate', 0)
  call s:init_option('vimtex_view_skim_reading_bar', 1)
  call s:init_option('vimtex_view_zathura_options', '')
endfunction

" }}}1
function! vimtex#check_plugin_clash() abort " {{{1
  let l:scriptnames = vimtex#util#command('scriptnames')

  let l:latexbox = !empty(filter(copy(l:scriptnames), "v:val =~# 'latex-box'"))
  if l:latexbox
    let l:polyglot = !empty(filter(copy(l:scriptnames), "v:val =~# 'polyglot'"))
    call vimtex#log#warning([
          \ 'Conflicting plugin detected: LaTeX-Box',
          \ 'vimtex does not work as expected when LaTeX-Box is installed!',
          \ 'Please disable or remove it to use vimtex!',
          \])
    if l:polyglot
      call vimtex#log#warning([
            \ 'LaTeX-Box is included with vim-polyglot and may be disabled with:',
            \ 'let g:polyglot_disabled = [''latex'']',
            \])
    endif
  endif
endfunction

" }}}1

function! s:init_option(option, default) abort " {{{1
  let l:option = 'g:' . a:option
  if !exists(l:option)
    let {l:option} = a:default
  elseif type(a:default) == type({})
    call vimtex#util#extend_recursive({l:option}, a:default, 'keep')
  endif
endfunction

" }}}1
function! s:init_highlights() abort " {{{1
  for [l:name, l:target] in [
        \ ['VimtexImapsArrow', 'Comment'],
        \ ['VimtexImapsLhs', 'ModeMsg'],
        \ ['VimtexImapsRhs', 'ModeMsg'],
        \ ['VimtexImapsWrapper', 'Type'],
        \ ['VimtexInfo', 'Question'],
        \ ['VimtexInfoTitle', 'PreProc'],
        \ ['VimtexInfoKey', 'PreProc'],
        \ ['VimtexInfoValue', 'Statement'],
        \ ['VimtexInfoOther', 'Normal'],
        \ ['VimtexMsg', 'ModeMsg'],
        \ ['VimtexSuccess', 'Statement'],
        \ ['VimtexTocHelp', 'helpVim'],
        \ ['VimtexTocHelpKey', 'ModeMsg'],
        \ ['VimtexTocHelpLayerOn', 'Statement'],
        \ ['VimtexTocHelpLayerOff', 'Comment'],
        \ ['VimtexTocTodo', 'Todo'],
        \ ['VimtexTocNum', 'Number'],
        \ ['VimtexTocSec0', 'Title'],
        \ ['VimtexTocSec1', 'Normal'],
        \ ['VimtexTocSec2', 'helpVim'],
        \ ['VimtexTocSec3', 'NonText'],
        \ ['VimtexTocSec4', 'Comment'],
        \ ['VimtexTocHotkey', 'Comment'],
        \ ['VimtexTocLabelsSecs', 'Statement'],
        \ ['VimtexTocLabelsEq', 'PreProc'],
        \ ['VimtexTocLabelsFig', 'Identifier'],
        \ ['VimtexTocLabelsTab', 'String'],
        \ ['VimtexTocIncl', 'Number'],
        \ ['VimtexTocInclPath', 'Normal'],
        \ ['VimtexWarning', 'WarningMsg'],
        \ ['VimtexError', 'ErrorMsg'],
        \]
    if !hlexists(l:name)
      silent execute 'highlight default link' l:name l:target
    endif
  endfor
endfunction

" }}}1
function! s:init_state() abort " {{{1
  call vimtex#state#init()
  call vimtex#state#init_local()
endfunction

" }}}1
function! s:init_buffer() abort " {{{1
  " Set Vim options
  for l:suf in [
        \ '.sty',
        \ '.cls',
        \ '.log',
        \ '.aux',
        \ '.bbl',
        \ '.out',
        \ '.blg',
        \ '.brf',
        \ '.cb',
        \ '.dvi',
        \ '.fdb_latexmk',
        \ '.fls',
        \ '.idx',
        \ '.ilg',
        \ '.ind',
        \ '.inx',
        \ '.pdf',
        \ '.synctex.gz',
        \ '.toc',
        \ ]
    execute 'set suffixes+=' . l:suf
  endfor
  setlocal suffixesadd=.sty,.tex,.cls
  setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
  setlocal commentstring=%%s
  setlocal iskeyword+=:
  setlocal includeexpr=vimtex#include#expr()
  let &l:include = g:vimtex#re#tex_include
  let &l:define  = '\\\([egx]\|char\|mathchar\|count\|dimen\|muskip\|skip'
  let &l:define .= '\|toks\)\=def\|\\font\|\\\(future\)\=let'
  let &l:define .= '\|\\new\(count\|dimen\|skip'
  let &l:define .= '\|muskip\|box\|toks\|read\|write\|fam\|insert\)'
  let &l:define .= '\|\\\(re\)\=new\(boolean\|command\|counter\|environment'
  let &l:define .= '\|font\|if\|length\|savebox'
  let &l:define .= '\|theorem\(style\)\=\)\s*\*\=\s*{\='
  let &l:define .= '\|DeclareMathOperator\s*{\=\s*'

  " Define autocommands
  augroup vimtex_buffers
    autocmd BufFilePre  <buffer> call s:filename_changed_pre()
    autocmd BufFilePost <buffer> call s:filename_changed_post()
    autocmd BufUnload   <buffer> call s:buffer_deleted('unload')
    autocmd BufWipeout  <buffer> call s:buffer_deleted('wipe')
  augroup END

  " Initialize buffer settings for sub modules
  for l:mod in s:modules
    if index(get(b:vimtex, 'disabled_modules', []), l:mod) >= 0 | continue | endif

    try
      call vimtex#{l:mod}#init_buffer()
    catch /E117.*#init_/
    catch /E127.*vimtex#profile#/
    endtry
  endfor
endfunction

" }}}1
function! s:init_default_mappings() abort " {{{1
  if !g:vimtex_mappings_enabled | return | endif

  function! s:map(mode, lhs, rhs, ...) abort
    if !hasmapto(a:rhs, a:mode)
          \ && index(get(g:vimtex_mappings_disable, a:mode, []), a:lhs) < 0
          \ && (empty(maparg(a:lhs, a:mode)) || a:0 > 0)
      silent execute a:mode . 'map <silent><nowait><buffer>' a:lhs a:rhs
    endif
  endfunction

  call s:map('n', '<localleader>li', '<plug>(vimtex-info)')
  call s:map('n', '<localleader>lI', '<plug>(vimtex-info-full)')
  call s:map('n', '<localleader>lx', '<plug>(vimtex-reload)')
  call s:map('n', '<localleader>lX', '<plug>(vimtex-reload-state)')
  call s:map('n', '<localleader>ls', '<plug>(vimtex-toggle-main)')
  call s:map('n', '<localleader>lq', '<plug>(vimtex-log)')

  call s:map('n', 'ds$', '<plug>(vimtex-env-delete-math)')
  call s:map('n', 'cs$', '<plug>(vimtex-env-change-math)')
  call s:map('n', 'dse', '<plug>(vimtex-env-delete)')
  call s:map('n', 'cse', '<plug>(vimtex-env-change)')
  call s:map('n', 'tse', '<plug>(vimtex-env-toggle-star)')

  call s:map('n', 'dsc',  '<plug>(vimtex-cmd-delete)')
  call s:map('n', 'csc',  '<plug>(vimtex-cmd-change)')
  call s:map('n', 'tsc',  '<plug>(vimtex-cmd-toggle-star)')
  call s:map('i', '<F7>', '<plug>(vimtex-cmd-create)')
  call s:map('n', '<F7>', '<plug>(vimtex-cmd-create)')
  call s:map('x', '<F7>', '<plug>(vimtex-cmd-create)')

  call s:map('n', 'dsd', '<plug>(vimtex-delim-delete)')
  call s:map('n', 'csd', '<plug>(vimtex-delim-change-math)')
  call s:map('n', 'tsd', '<plug>(vimtex-delim-toggle-modifier)')
  call s:map('x', 'tsd', '<plug>(vimtex-delim-toggle-modifier)')
  call s:map('n', 'tsD', '<plug>(vimtex-delim-toggle-modifier-reverse)')
  call s:map('x', 'tsD', '<plug>(vimtex-delim-toggle-modifier-reverse)')
  call s:map('i', ']]',  '<plug>(vimtex-delim-close)')

  if g:vimtex_compiler_enabled
    call s:map('n', '<localleader>ll', '<plug>(vimtex-compile)')
    call s:map('n', '<localleader>lo', '<plug>(vimtex-compile-output)')
    call s:map('n', '<localleader>lL', '<plug>(vimtex-compile-selected)')
    call s:map('x', '<localleader>lL', '<plug>(vimtex-compile-selected)')
    call s:map('n', '<localleader>lk', '<plug>(vimtex-stop)')
    call s:map('n', '<localleader>lK', '<plug>(vimtex-stop-all)')
    call s:map('n', '<localleader>le', '<plug>(vimtex-errors)')
    call s:map('n', '<localleader>lc', '<plug>(vimtex-clean)')
    call s:map('n', '<localleader>lC', '<plug>(vimtex-clean-full)')
    call s:map('n', '<localleader>lg', '<plug>(vimtex-status)')
    call s:map('n', '<localleader>lG', '<plug>(vimtex-status-all)')
  endif

  if g:vimtex_motion_enabled
    " These are forced in order to overwrite matchit mappings
    call s:map('n', '%', '<plug>(vimtex-%)', 1)
    call s:map('x', '%', '<plug>(vimtex-%)', 1)
    call s:map('o', '%', '<plug>(vimtex-%)', 1)

    call s:map('n', ']]', '<plug>(vimtex-]])')
    call s:map('n', '][', '<plug>(vimtex-][)')
    call s:map('n', '[]', '<plug>(vimtex-[])')
    call s:map('n', '[[', '<plug>(vimtex-[[)')
    call s:map('x', ']]', '<plug>(vimtex-]])')
    call s:map('x', '][', '<plug>(vimtex-][)')
    call s:map('x', '[]', '<plug>(vimtex-[])')
    call s:map('x', '[[', '<plug>(vimtex-[[)')
    call s:map('o', ']]', '<plug>(vimtex-]])')
    call s:map('o', '][', '<plug>(vimtex-][)')
    call s:map('o', '[]', '<plug>(vimtex-[])')
    call s:map('o', '[[', '<plug>(vimtex-[[)')

    call s:map('n', ']M', '<plug>(vimtex-]M)')
    call s:map('n', ']m', '<plug>(vimtex-]m)')
    call s:map('n', '[M', '<plug>(vimtex-[M)')
    call s:map('n', '[m', '<plug>(vimtex-[m)')
    call s:map('x', ']M', '<plug>(vimtex-]M)')
    call s:map('x', ']m', '<plug>(vimtex-]m)')
    call s:map('x', '[M', '<plug>(vimtex-[M)')
    call s:map('x', '[m', '<plug>(vimtex-[m)')
    call s:map('o', ']M', '<plug>(vimtex-]M)')
    call s:map('o', ']m', '<plug>(vimtex-]m)')
    call s:map('o', '[M', '<plug>(vimtex-[M)')
    call s:map('o', '[m', '<plug>(vimtex-[m)')

    call s:map('n', ']/', '<plug>(vimtex-]/)')
    call s:map('n', ']*', '<plug>(vimtex-]*)')
    call s:map('n', '[/', '<plug>(vimtex-[/)')
    call s:map('n', '[*', '<plug>(vimtex-[*)')
    call s:map('x', ']/', '<plug>(vimtex-]/)')
    call s:map('x', ']*', '<plug>(vimtex-]*)')
    call s:map('x', '[/', '<plug>(vimtex-[/)')
    call s:map('x', '[*', '<plug>(vimtex-[*)')
    call s:map('o', ']/', '<plug>(vimtex-]/)')
    call s:map('o', ']*', '<plug>(vimtex-]*)')
    call s:map('o', '[/', '<plug>(vimtex-[/)')
    call s:map('o', '[*', '<plug>(vimtex-[*)')
  endif

  if g:vimtex_text_obj_enabled
    call s:map('x', 'id', '<plug>(vimtex-id)')
    call s:map('x', 'ad', '<plug>(vimtex-ad)')
    call s:map('o', 'id', '<plug>(vimtex-id)')
    call s:map('o', 'ad', '<plug>(vimtex-ad)')
    call s:map('x', 'i$', '<plug>(vimtex-i$)')
    call s:map('x', 'a$', '<plug>(vimtex-a$)')
    call s:map('o', 'i$', '<plug>(vimtex-i$)')
    call s:map('o', 'a$', '<plug>(vimtex-a$)')
    call s:map('x', 'iP', '<plug>(vimtex-iP)')
    call s:map('x', 'aP', '<plug>(vimtex-aP)')
    call s:map('o', 'iP', '<plug>(vimtex-iP)')
    call s:map('o', 'aP', '<plug>(vimtex-aP)')

    if vimtex#text_obj#targets#enabled()
      call vimtex#text_obj#targets#init()

      " These are handled explicitly to avoid conflict with gitgutter
      call s:map('x', 'ic', '<plug>(vimtex-targets-i)c')
      call s:map('x', 'ac', '<plug>(vimtex-targets-a)c')
      call s:map('o', 'ic', '<plug>(vimtex-targets-i)c')
      call s:map('o', 'ac', '<plug>(vimtex-targets-a)c')
    else
      if g:vimtex_text_obj_variant ==# 'targets'
        call vimtex#log#warning(
              \ "Ignoring g:vimtex_text_obj_variant = 'targets'"
              \ . " because 'g:loaded_targets' does not exist or is 0.")
      endif
      let g:vimtex_text_obj_variant = 'vimtex'

      call s:map('x', 'ie', '<plug>(vimtex-ie)')
      call s:map('x', 'ae', '<plug>(vimtex-ae)')
      call s:map('o', 'ie', '<plug>(vimtex-ie)')
      call s:map('o', 'ae', '<plug>(vimtex-ae)')
      call s:map('x', 'ic', '<plug>(vimtex-ic)')
      call s:map('x', 'ac', '<plug>(vimtex-ac)')
      call s:map('o', 'ic', '<plug>(vimtex-ic)')
      call s:map('o', 'ac', '<plug>(vimtex-ac)')
    endif
  endif

  if g:vimtex_toc_enabled
    call s:map('n', '<localleader>lt', '<plug>(vimtex-toc-open)')
    call s:map('n', '<localleader>lT', '<plug>(vimtex-toc-toggle)')
  endif

  if has_key(b:vimtex, 'viewer')
    call s:map('n', '<localleader>lv', '<plug>(vimtex-view)')
    if has_key(b:vimtex.viewer, 'reverse_search')
      call s:map('n', '<localleader>lr', '<plug>(vimtex-reverse-search)')
    endif
  endif

  if g:vimtex_imaps_enabled
    call s:map('n', '<localleader>lm', '<plug>(vimtex-imaps-list)')
  endif

  if g:vimtex_doc_enabled
    call s:map('n', 'K', '<plug>(vimtex-doc-package)')
  endif
endfunction

" }}}1

function! s:filename_changed_pre() abort " {{{1
  let s:filename_changed = expand('%:p') ==# b:vimtex.tex
endfunction

" }}}1
function! s:filename_changed_post() abort " {{{1
  if s:filename_changed
    let l:base_old = b:vimtex.base
    let b:vimtex.tex = fnamemodify(expand('%'), ':p')
    let b:vimtex.base = fnamemodify(b:vimtex.tex, ':t')
    let b:vimtex.name = fnamemodify(b:vimtex.tex, ':t:r')

    call vimtex#log#warning('Filename change detected')
    call vimtex#log#info('Old filename: ' . l:base_old)
    call vimtex#log#info('New filename: ' . b:vimtex.base)

    if has_key(b:vimtex, 'compiler')
      if b:vimtex.compiler.is_running()
        call vimtex#log#warning('Compilation stopped!')
        call vimtex#compiler#stop()
      endif
      let b:vimtex.compiler.target = b:vimtex.base
      let b:vimtex.compiler.target_path = b:vimtex.tex
    endif
  endif
endfunction

" }}}1
function! s:buffer_deleted(reason) abort " {{{1
  "
  " We need a simple cache of buffer ids because a buffer unload might clear
  " buffer variables, so that a subsequent buffer wipe will not trigger a full
  " cleanup. By caching the buffer id, we should avoid this issue.
  "
  let l:file = expand('<afile>')
  if !exists('s:buffer_cache')
    let s:buffer_cache = {}
  endif
  if !has_key(s:buffer_cache, l:file)
    let s:buffer_cache[l:file] = getbufvar(l:file, 'vimtex_id', -1)
  endif

  if a:reason ==# 'wipe' || &hidden
    call vimtex#state#cleanup(s:buffer_cache[l:file])
  endif
endfunction

" }}}1
function! s:quit() abort " {{{1
  for l:state in vimtex#state#list_all()
    call l:state.cleanup()
  endfor
endfunction

" }}}1


" {{{1 Initialize module

let s:modules = map(
      \ glob(fnamemodify(expand('<sfile>'), ':r') . '/*.vim', 0, 1),
      \ 'fnamemodify(v:val, '':t:r'')')

" }}}1
