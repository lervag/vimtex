" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#init() " {{{1
  call s:check_version()

  call s:init_options()
  call s:init_highlights()

  "
  " First initialize buffer options and construct (if necessary) the vimtex
  " data blob.
  "
  call s:init_buffer()

  "
  " Parse the document to set local options
  "
  call s:init_local_options()

  "
  " Then we initialize the modules for the current buffer
  "
  call s:init_modules()


  "
  " Initialize local blob (if main file is different then current file)
  "
  call s:init_local_blob()

  "
  " Finally we create the mappings
  "
  call s:init_mappings()

  "
  " Allow custom configuration through an event hook
  "
  if exists('#User#VimtexEventInitPost')
    doautocmd User VimtexEventInitPost
  endif
endfunction

" }}}1
function! vimtex#toggle_main() " {{{1
  if exists('b:vimtex_local')
    let b:vimtex_local.active = !b:vimtex_local.active

    let b:vimtex_id = b:vimtex_local.active
          \ ? b:vimtex_local.sub_id
          \ : b:vimtex_local.main_id
    let b:vimtex = g:vimtex_data[b:vimtex_id]

    call vimtex#echo#status(['vimtex: ',
          \ ['Normal', 'Changed to `'],
          \ ['VimtexSuccess', b:vimtex.base],
          \ ['Normal', "' "],
          \ ['VimtexInfo', b:vimtex_local.active ? '[local]' : '[main]' ]])
  endif
endfunction

" }}}1


function! s:check_version() " {{{1
  if get(g:, 'vimtex_disable_version_warning', 0)
    return
  endif

  if v:version <= 703 && !has('patch544')
    echoerr 'vimtex error: Please use Vim version 7.3.544 or newer!'
  endif
endfunction

" }}}1

function! s:init_options() " {{{1
  call s:init_option('vimtex_complete_enabled', 1)
  call s:init_option('vimtex_complete_close_braces', 0)
  call s:init_option('vimtex_complete_recursive_bib', 0)

  call s:init_option('vimtex_echo_ignore_wait', 0)

  call s:init_option('vimtex_fold_enabled', 0)
  if &diff
    let g:vimtex_fold_manual = 0
  else
    call s:init_option('vimtex_fold_manual', 0)
  endif
  call s:init_option('vimtex_fold_comments', 0)
  call s:init_option('vimtex_fold_levelmarker', '*')
  call s:init_option('vimtex_fold_preamble', 1)
  call s:init_option('vimtex_fold_envs', 1)
  call s:init_option('vimtex_fold_markers', 1)
  call s:init_option('vimtex_fold_parts',
        \ [
        \   'part',
        \   'appendix',
        \   'frontmatter',
        \   'mainmatter',
        \   'backmatter',
        \ ])
  call s:init_option('vimtex_fold_sections',
        \ [
        \   'chapter',
        \   'section',
        \   'subsection',
        \   'subsubsection',
        \ ])
  call s:init_option('vimtex_fold_commands_default', {
        \ 'hypersetup' : 'single',
        \ 'tikzset' : 'single',
        \ 'usepackage' : 'single_opt',
        \ 'includepdf' : 'single_opt',
        \ '%(re)?new%(command|environment)' : 'multi',
        \ 'providecommand' : 'multi',
        \ 'presetkeys' : 'multi',
        \ 'Declare%(Multi|Auto)?CiteCommand' : 'multi',
        \ 'Declare%(Index)?%(Field|List|Name)%(Format|Alias)' : 'multi',
        \})

  call s:init_option('vimtex_format_enabled', 0)

  call s:init_option('vimtex_imaps_enabled', 1)
  call s:init_option('vimtex_imaps_leader', '`')
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
        \ { 'lhs' : '<=', 'rhs' : '\leq' },
        \ { 'lhs' : '>=', 'rhs' : '\geq' },
        \ { 'lhs' : '[',  'rhs' : '\subseteq' },
        \ { 'lhs' : ']',  'rhs' : '\supseteq' },
        \ { 'lhs' : '(',  'rhs' : '\subset' },
        \ { 'lhs' : ')',  'rhs' : '\supset' },
        \ { 'lhs' : 'A',  'rhs' : '\forall' },
        \ { 'lhs' : 'E',  'rhs' : '\exists' },
        \ { 'lhs' : 'qj', 'rhs' : '\downarrow' },
        \ { 'lhs' : 'qJ', 'rhs' : '\Downarrow' },
        \ { 'lhs' : 'qk', 'rhs' : '\uparrow' },
        \ { 'lhs' : 'qK', 'rhs' : '\Uparrow' },
        \ { 'lhs' : 'qh', 'rhs' : '\leftarrow' },
        \ { 'lhs' : 'qH', 'rhs' : '\Leftarrow' },
        \ { 'lhs' : 'ql', 'rhs' : '\rightarrow' },
        \ { 'lhs' : 'qL', 'rhs' : '\Rightarrow' },
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

  call s:init_option('vimtex_index_hide_line_numbers', 1)
  call s:init_option('vimtex_index_resize', 0)
  call s:init_option('vimtex_index_show_help', 1)
  call s:init_option('vimtex_index_split_pos', 'vert leftabove')
  call s:init_option('vimtex_index_split_width', 30)

  call s:init_option('vimtex_motion_enabled', 1)
  call s:init_option('vimtex_motion_matchparen', 1)

  call s:init_option('vimtex_labels_enabled', 1)

  call s:init_option('vimtex_latexmk_enabled', 1)
  call s:init_option('vimtex_latexmk_build_dir', '')
  call s:init_option('vimtex_latexmk_progname',
        \ get(v:, 'progpath', get(v:, 'progname')))
  call s:init_option('vimtex_latexmk_callback_hooks', [])
  call s:init_option('vimtex_latexmk_background', 0)
  call s:init_option('vimtex_latexmk_callback', 1)
  call s:init_option('vimtex_latexmk_continuous', 1)
  call s:init_option('vimtex_latexmk_options',
        \ '-verbose -pdf -file-line-error -synctex=1 -interaction=nonstopmode')

  call s:init_option('vimtex_quickfix_autojump', '0')
  call s:init_option('vimtex_quickfix_mode', '2')
  call s:init_option('vimtex_quickfix_open_on_warning', '1')

  call s:init_option('vimtex_text_obj_enabled', 1)
  call s:init_option('vimtex_text_obj_linewise_operators', ['d', 'y'])

  call s:init_option('vimtex_toc_enabled', 1)
  call s:init_option('vimtex_toc_fold', 0)
  call s:init_option('vimtex_toc_fold_levels', 10)
  call s:init_option('vimtex_toc_number_width', 0)
  call s:init_option('vimtex_toc_secnumdepth', 3)
  call s:init_option('vimtex_toc_show_numbers', 1)
  call s:init_option('vimtex_toc_show_preamble', 1)

  call s:init_option('vimtex_view_enabled', 1)
  call s:init_option('vimtex_view_automatic', 1)
  call s:init_option('vimtex_view_method', 'general')
  call s:init_option('vimtex_view_use_temp_files', 0)
  call s:init_option('vimtex_view_general_viewer', get({
        \ 'linux' : 'xdg-open',
        \ 'mac'   : 'open',
        \}, vimtex#util#get_os(), ''))
  call s:init_option('vimtex_view_general_options', '@pdf')
  call s:init_option('vimtex_view_general_options_latexmk', '')
  call s:init_option('vimtex_view_mupdf_options', '')
  call s:init_option('vimtex_view_mupdf_send_keys', '')
  call s:init_option('vimtex_view_zathura_options', '')
endfunction

" }}}1
function! s:init_option(option, default) " {{{1
  let l:option = 'g:' . a:option
  if !exists(l:option)
    let {l:option} = a:default
  endif
endfunction

" }}}1
function! s:init_highlights() " {{{1
  for [l:name, l:target] in [
        \ ['VimtexImapsArrow', 'Comment'],
        \ ['VimtexImapsLhs', 'ModeMsg'],
        \ ['VimtexImapsRhs', 'ModeMsg'],
        \ ['VimtexImapsWrapper', 'Type'],
        \ ['VimtexIndexHelp', 'helpVim'],
        \ ['VimtexIndexLine', 'ModeMsg'],
        \ ['VimtexInfo', 'Question'],
        \ ['VimtexLabelsChap', 'PreProc'],
        \ ['VimtexLabelsEq', 'Statement'],
        \ ['VimtexLabelsFig', 'Identifier'],
        \ ['VimtexLabelsHelp', 'helpVim'],
        \ ['VimtexLabelsLine', 'Todo'],
        \ ['VimtexLabelsSec', 'Type'],
        \ ['VimtexLabelsTab', 'String'],
        \ ['VimtexMsg', 'ModeMsg'],
        \ ['VimtexSuccess', 'Statement'],
        \ ['VimtexTocHelp', 'helpVim'],
        \ ['VimtexTocNum', 'Number'],
        \ ['VimtexTocSec0', 'Title'],
        \ ['VimtexTocSec1', 'Normal'],
        \ ['VimtexTocSec2', 'helpVim'],
        \ ['VimtexTocSec3', 'NonText'],
        \ ['VimtexTocSec4', 'Comment'],
        \ ['VimtexTocTag', 'Directory'],
        \ ['VimtexWarning', 'WarningMsg'],
        \]
    if !hlexists(l:name)
      silent execute 'highlight default link' l:name l:target
    endif
  endfor
endfunction

function! s:init_buffer() " {{{1
  "
  " First we set some vim options
  "
  let s:save_cpo = &cpo
  set cpo&vim

  " Ensure tex files are prioritized when listing files
  for suf in [
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
    execute 'set suffixes+=' . suf
  endfor

  setlocal suffixesadd=.tex,.sty,.cls
  setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
  setlocal commentstring=%%s
  setlocal includeexpr=vimtex#include#expr()

  let &l:include = '\v\\%(input|include)\{'

  let &l:define  = '\\\([egx]\|char\|mathchar\|count\|dimen\|muskip\|skip'
  let &l:define .= '\|toks\)\=def\|\\font\|\\\(future\)\=let'
  let &l:define .= '\|\\new\(count\|dimen\|skip'
  let &l:define .= '\|muskip\|box\|toks\|read\|write\|fam\|insert\)'
  let &l:define .= '\|\\\(re\)\=new\(boolean\|command\|counter\|environment'
  let &l:define .= '\|font\|if\|length\|savebox'
  let &l:define .= '\|theorem\(style\)\=\)\s*\*\=\s*{\='
  let &l:define .= '\|DeclareMathOperator\s*{\=\s*'

  let &cpo = s:save_cpo
  unlet s:save_cpo

  "
  " Next we initialize the data blob
  "

  " Create container for data blobs if it does not exist
  let g:vimtex_data = get(g:, 'vimtex_data', {})

  " Get main file number and check if data blob already exists
  let main = s:get_main()
  let id   = s:get_id(main)

  " Create data blob
  if id >= 0
    " Link to existing blob
    let b:vimtex_id = id
    let b:vimtex = g:vimtex_data[id]
  else
    " Create new blob
    let b:vimtex = s:vimtex.init(main)
    let s:vimtex_next_id = get(s:, 'vimtex_next_id', -1) + 1
    let b:vimtex_id = s:vimtex_next_id
    let g:vimtex_data[b:vimtex_id] = b:vimtex
  endif

  "
  " Define commands and mappings
  "

  " Define commands
  command! -buffer       VimtexToggleMain   call vimtex#toggle_main()

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-toggle-main) :VimtexToggleMain<cr>

  "
  " Attach autocommands
  "

  augroup vimtex_buffers
    au BufFilePre  <buffer> call s:filename_changed_pre()
    au BufFilePost <buffer> call s:filename_changed_post()
    au BufLeave    <buffer> call s:buffer_left()
    au BufDelete   <buffer> call s:buffer_deleted()
    au QuitPre     <buffer> call s:buffer_deleted(b:vimtex_id)
  augroup END
endfunction

" }}}1
function! s:init_mappings() " {{{1
  if !get(g:,'vimtex_mappings_enabled', 1) | return | endif

  function! s:map(mode, lhs, rhs, ...)
    if (a:0 > 0) || (maparg(a:lhs, a:mode) ==# '')
      silent execute a:mode . 'map <silent><buffer>' a:lhs a:rhs
    endif
  endfunction

  call s:map('n', '<localleader>li', '<plug>(vimtex-info)')
  call s:map('n', '<localleader>lI', '<plug>(vimtex-info-full)')
  call s:map('n', '<localleader>lx', '<plug>(vimtex-reload)')
  call s:map('n', '<localleader>ls', '<plug>(vimtex-toggle-main)')

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
  call s:map('i', ']]',  '<plug>(vimtex-delim-close)')

  if get(g:, 'vimtex_latexmk_enabled', 0)
    call s:map('n', '<localleader>ll', '<plug>(vimtex-compile-toggle)')
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

  if get(g:, 'vimtex_motion_enabled', 0)
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

    " These are forced in order to overwrite matchit mappings
    call s:map('n', '%', '<plug>(vimtex-%)', 1)
    call s:map('x', '%', '<plug>(vimtex-%)', 1)
    call s:map('o', '%', '<plug>(vimtex-%)', 1)
  endif

  if get(g:, 'vimtex_text_obj_enabled', 0)
    call s:map('x', 'ic', '<plug>(vimtex-ic)')
    call s:map('x', 'ac', '<plug>(vimtex-ac)')
    call s:map('o', 'ic', '<plug>(vimtex-ic)')
    call s:map('o', 'ac', '<plug>(vimtex-ac)')
    call s:map('x', 'id', '<plug>(vimtex-id)')
    call s:map('x', 'ad', '<plug>(vimtex-ad)')
    call s:map('o', 'id', '<plug>(vimtex-id)')
    call s:map('o', 'ad', '<plug>(vimtex-ad)')
    call s:map('x', 'ie', '<plug>(vimtex-ie)')
    call s:map('x', 'ae', '<plug>(vimtex-ae)')
    call s:map('o', 'ie', '<plug>(vimtex-ie)')
    call s:map('o', 'ae', '<plug>(vimtex-ae)')
    call s:map('x', 'i$', '<plug>(vimtex-i$)')
    call s:map('x', 'a$', '<plug>(vimtex-a$)')
    call s:map('o', 'i$', '<plug>(vimtex-i$)')
    call s:map('o', 'a$', '<plug>(vimtex-a$)')
  endif

  if get(g:, 'vimtex_toc_enabled', 0)
    call s:map('n', '<localleader>lt', '<plug>(vimtex-toc-open)')
    call s:map('n', '<localleader>lT', '<plug>(vimtex-toc-toggle)')
  endif

  if get(g:, 'vimtex_labels_enabled', 0)
    call s:map('n', '<localleader>ly', '<plug>(vimtex-labels-open)')
    call s:map('n', '<localleader>lY', '<plug>(vimtex-labels-toggle)')
  endif

  if has_key(b:vimtex, 'viewer')
    call s:map('n', '<localleader>lv', '<plug>(vimtex-view)')
    if has_key(b:vimtex.viewer, 'reverse_search')
      call s:map('n', '<localleader>lr', '<plug>(vimtex-reverse-search)')
    endif
  endif

  if get(g:, 'vimtex_imaps_enabled', 0)
    call s:map('n', '<localleader>lm', '<plug>(vimtex-imaps-list)')
  endif
endfunction

" }}}1
function! s:init_modules() " {{{1
  for module in s:modules
    if index(get(s:, 'disabled_modules', []), module) >= 0 | continue | endif

    try
      call vimtex#{module}#init_buffer()
    catch /E117.*#init_/
    endtry
  endfor
endfunction

" }}}1
function! s:init_local_blob() " {{{1
  let l:filename = expand('%:p')

  if b:vimtex.tex !=# l:filename
    let l:vimtex_id = s:get_id(l:filename)
    if l:vimtex_id >= 0
      let b:vimtex_local = {
            \ 'active' : 0,
            \ 'main_id' : b:vimtex_id,
            \ 'sub_id' : l:vimtex_id,
            \}
    else
      let l:local = deepcopy(b:vimtex)
      let l:local.tex = l:filename
      let l:local.pid = 0
      let l:local.name = fnamemodify(l:filename, ':t:r')
      let l:local.root = fnamemodify(l:filename, ':h')
      let l:local.base = fnamemodify(l:filename, ':t')

      let s:vimtex_next_id += 1
      let g:vimtex_data[s:vimtex_next_id] = l:local

      let b:vimtex_local = {
            \ 'active' : 0,
            \ 'main_id' : b:vimtex_id,
            \ 'sub_id' : s:vimtex_next_id,
            \}
    endif
  endif
endfunction

" }}}1
function! s:init_local_options() " {{{1
  let l:engine_regex =
        \ '\v^\c\s*\%\s*\!?\s*tex\s+%(TS-)?program\s*\=\s*\zs.*\ze\s*$'
  let l:engine_list = {
        \ 'pdflatex'         : '',
        \ 'lualatex'         : '-lualatex',
        \ 'xelatex'          : '-xelatex',
        \ 'context (pdftex)' : '-pdflatex=texexec',
        \ 'context (luatex)' : '-pdflatex=context',
        \ 'context (xetex)'  : '-pdflatex=''texexec --xtx''',
        \}

  "
  " Initialize local configuration
  "
  let b:vimtex.packages = {}
  let b:vimtex.sources = []
  let b:vimtex.engine = ''

  "
  " Parse the preamble for packages and other configuration
  "
  for l:line in vimtex#parser#tex(b:vimtex.tex, {
        \ 'detailed' : 0,
        \ 're_stop' : '\\begin\s*{document}',
        \})
    if l:line =~# '\\usepackage.*{tikz}'
      let b:vimtex.packages.tikz = 1
      continue
    endif

    let l:engine = matchstr(l:line, l:engine_regex)
    if !empty(l:engine)
      let b:vimtex.engine = get(l:engine_list, tolower(l:engine), '')
      continue
    endif
  endfor

  "
  " Create list of TeX source files
  "
  for [l:file, l:lnum, l:line] in vimtex#parser#tex(b:vimtex.tex)
    let l:cand = substitute(l:file, '\M' . b:vimtex.root, '', '')
    if l:cand[0] ==# '/' | let l:cand = l:cand[1:] | endif

    if index(b:vimtex.sources, l:cand) < 0
      call add(b:vimtex.sources, l:cand)
    endif
  endfor
endfunction

" }}}1

function! s:get_id(main) " {{{1
  for [id, data] in items(g:vimtex_data)
    if data.tex == a:main
      return str2nr(id)
    endif
  endfor

  return -1
endfunction

function! s:get_main() " {{{1
  "
  " Check if the current file is a main file
  "
  if s:file_is_main(expand('%:p'))
    return expand('%:p')
  endif

  "
  " Use buffer variable if it exists
  "
  if exists('b:vimtex_main') && filereadable(b:vimtex_main)
    return fnamemodify(b:vimtex_main, ':p')
  endif

  "
  " Search for TEX root specifier at the beginning of file. This is used by
  " several other plugins and editors.
  "
  let l:candidate = s:get_main_from_specifier(
        \ '^\c\s*%\s*!\?\s*tex\s\+root\s*=\s*\zs.*\ze\s*$')
  if !empty(l:candidate)
    return l:candidate
  endif

  "
  " Support for subfiles package
  "
  let l:candidate = s:get_main_from_specifier(
        \ '^\C\s*\\documentclass\[\zs.*\ze\]{subfiles}')
  if !empty(l:candidate)
    return l:candidate
  endif

  "
  " Search for .latexmain-specifier
  "
  let l:candidate = s:get_main_latexmain(expand('%:p'))
  if !empty(l:candidate)
    return l:candidate
  endif

  "
  " Check if we are class or style file
  "
  if index(['cls', 'sty'], expand('%:e')) >= 0
    let id = getbufvar('#', 'vimtex_id', -1)
    if id >= 0
      return g:vimtex_data[id].tex
    else
      let s:disabled_modules = ['latexmk', 'view']
      return expand('%:p')
    endif
  endif

  "
  " Search for main file recursively through include specifiers
  "
  if !get(g:, 'vimtex_disable_recursive_main_file_detection', 0)
    let l:candidate = s:get_main_recurse()
    if l:candidate !=# ''
      return l:candidate
    endif
  endif

  "
  " Fallback to the current file
  "
  return expand('%:p')
endfunction

" }}}1
function! s:get_main_from_specifier(spec) " {{{1
  for l:line in getline(1, 5)
    let l:filename = matchstr(l:line, a:spec)
    if len(l:filename) > 0
      if l:filename[0] ==# '/'
        if filereadable(l:filename) | return l:filename | endif
      else
        " The candidate may be relative both to the current buffer file and to
        " the working directory (for subfile package)
        for l:candidate in map([
              \   expand('%:p:h'),
              \   getcwd()],
              \ 'simplify(v:val . ''/'' . l:filename)')
          if filereadable(l:candidate) | return l:candidate | endif
        endfor
      endif
    endif
  endfor

  return ''
endfunction

" }}}1
function! s:get_main_latexmain(file) " {{{1
  for l:cand in s:findfiles_recursive('*.latexmain', expand('%:p:h'))
    let l:cand = fnamemodify(l:cand, ':p:r')
    if s:file_reaches_current(l:cand)
      return l:cand
    endif
  endfor

  return ''
endfunction

function! s:get_main_recurse(...) " {{{1
  "
  " Either start the search from the original file, or check if the supplied
  " file is a main file (or invalid)
  "
  if a:0 == 0
    let l:file = expand('%:p')
  else
    let l:file = a:1

    if s:file_is_main(l:file)
      return l:file
    elseif !filereadable(l:file)
      return ''
    endif
  endif

  "
  " Search through candidates found recursively upwards in the directory tree
  "
  for l:cand in s:findfiles_recursive('*.tex', fnamemodify(l:file, ':p:h'))
    " Avoid infinite recursion (checking the same file repeatedly)
    if l:cand == l:file | continue | endif

    let l:file_re = '\s*((.*)\/)?' . fnamemodify(l:file, ':t:r')

    let l:filter  = 'v:val =~# ''\v'
    let l:filter .= '\\%(input|include)\{' . l:file_re
    let l:filter .= '|\\subimport\{[^\}]*\}\{' . l:file_re
    let l:filter .= ''''

    if len(filter(readfile(l:cand), l:filter)) > 0
      return s:get_main_recurse(fnamemodify(l:cand, ':p'))
    endif
  endfor
endfunction

" }}}1
function! s:file_is_main(file) " {{{1
  if !filereadable(a:file) | return 0 | endif

  "
  " Check if a:file is a main file by looking for the \documentclass command,
  " but ignore \documentclass[...]{subfiles}
  "
  let l:lines = readfile(a:file, 0, 50)
  call filter(l:lines, 'v:val !~# ''{subfiles}''')
  call filter(l:lines, 'v:val =~# ''\C\\documentclass\_\s*[\[{]''')
  return len(l:lines) > 0
endfunction

" }}}1
function! s:file_reaches_current(file) " {{{1
  if !filereadable(a:file) | return 0 | endif

  for l:line in readfile(a:file)
    let l:file = matchstr(l:line,
          \ '\v\\%(input|include|subimport\{[^\}]*\})\s*\{\zs\f+')
    if empty(l:file) | continue | endif

    if l:file[0] !=# '/'
      let l:file = fnamemodify(a:file, ':h') . '/' . l:file
    endif

    if l:file !~# '\.tex$'
      let l:file .= '.tex'
    endif

    if expand('%:p') ==# l:file
          \ || s:file_reaches_current(l:file)
      return 1
    endif
  endfor

  return 0
endfunction

" }}}1
function! s:findfiles_recursive(expr, path) " {{{1
  let l:path = a:path
  let l:dirs = l:path
  while l:path != fnamemodify(l:path, ':h')
    let l:path = fnamemodify(l:path, ':h')
    let l:dirs .= ',' . l:path
  endwhile
  return split(globpath(fnameescape(l:dirs), a:expr), '\n')
endfunction

" }}}1

function! s:filename_changed_pre() " {{{1
  let thisfile = fnamemodify(expand('%'), ':p')
  let s:filename_changed = thisfile ==# b:vimtex.tex
  let s:filename_old = b:vimtex.base
endfunction

" }}}1
function! s:filename_changed_post() " {{{1
  if s:filename_changed
    let b:vimtex.tex = fnamemodify(expand('%'), ':p')
    let b:vimtex.base = fnamemodify(b:vimtex.tex, ':t')
    let b:vimtex.name = fnamemodify(b:vimtex.tex, ':t:r')
    let message = ['vimtex: ',
          \ ['VimtexWarning', 'Filename change detected!'],
          \ "\n  Old filename: ", ['VimtexInfo', s:filename_old],
          \ "\n  New filename: ", ['VimtexInfo', b:vimtex.base]]

    if b:vimtex.pid
      let message += ["\n  latexmk process: ",
            \ ['VimtexInfo', b:vimtex.pid],
            \ ['VimtexWarning', ' killed!']]
      call vimtex#latexmk#stop()
    endif

    " Update viewer output file names
    if exists('b:vimtex.viewer.out')
      call vimtex#view#common#use_temp_files_p(b:vimtex.viewer)
    endif

    call vimtex#echo#status(message)
  endif
endfunction

" }}}1

let s:vimtex = {}

function! s:vimtex.init(main_path) abort dict " {{{1
  let l:new = deepcopy(self)
  let l:new.tex  = a:main_path
  let l:new.root = fnamemodify(l:new.tex, ':h')
  let l:new.base = fnamemodify(l:new.tex, ':t')
  let l:new.name = fnamemodify(l:new.tex, ':t:r')
  return l:new
endfunction

" }}}1
function! s:vimtex.log() abort dict " {{{1
  return self.ext('log')
endfunction

" }}}1
function! s:vimtex.aux() abort dict " {{{1
  return self.ext('aux')
endfunction

" }}}1
function! s:vimtex.out(...) abort dict " {{{1
  return call(self.ext, ['pdf'] + a:000, self)
endfunction

" }}}1
function! s:vimtex.ext(ext, ...) abort dict " {{{1
  " First check build dir (latexmk -output_directory option)
  if get(g:, 'vimtex_compiler_build_dir', '') !=# ''
    let cand = g:vimtex_compiler_build_dir . '/' . self.name . '.' . a:ext
    if g:vimtex_compiler_build_dir[0] !=# '/'
      let cand = self.root . '/' . cand
    endif
    if a:0 > 0 || filereadable(cand)
      return fnamemodify(cand, ':p')
    endif
  endif

  " Next check for file in project root folder
  let cand = self.root . '/' . self.name . '.' . a:ext
  if a:0 > 0 || filereadable(cand)
    return fnamemodify(cand, ':p')
  endif

  " Finally return empty string if no entry is found
  return ''
endfunction

" }}}1
function! s:vimtex.pprint_items() abort dict " {{{1
  let l:items = [
        \ ['name', self.name],
        \ ['base', self.base],
        \ ['root', self.root],
        \ ['tex', self.tex],
        \ ['out', self.out()],
        \ ['log', self.log()],
        \ ['aux', self.aux()],
        \]

  if !empty(self.engine)
    call add(l:items, ['engine', self.engine])
  endif

  if len(self.sources) >= 2
    call add(l:items, ['source files', self.sources])
  endif

  if !empty(self.packages)
    call add(l:items, ['packages', self.packages])
  endif

  call add(l:items, ['compiler', get(self, 'compiler', {})])
  call add(l:items, ['viewer', get(self, 'viewer', {})])

  return [['vimtex project', l:items]]
endfunction

" }}}1

function! s:buffer_left() " {{{1
  let s:vimtex_id = b:vimtex_id
endfunction

" }}}1
function! s:buffer_deleted(...) " {{{1
  "
  " Get the relevant blob id
  "
  let l:vimtex_id = a:0 > 0 ? a:1 : get(s:, 'vimtex_id', -1)
  if exists('s:vimtex_id') | unlet s:vimtex_id | endif
  if !has_key(g:vimtex_data, l:vimtex_id) | return | endif

  "
  " Count the number of open buffers for the given blob
  "
  let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  let l:vimtex_ids = map(l:buffers, 'getbufvar(v:val, ''vimtex_id'', -1)')
  let l:count = count(l:vimtex_ids, l:vimtex_id)

  "
  " Check if the deleted buffer was the last remaining buffer of an opened
  " latex project
  "
  if l:count <= 1
    let l:vimtex = g:vimtex_data[l:vimtex_id]

    if exists('#User#VimtexEventQuit')
      if exists('b:vimtex')
        let b:vimtex_tmp = b:vimtex
      endif
      let b:vimtex = l:vimtex
      doautocmd User VimtexEventQuit
      if exists('b:vimtex_tmp')
        let b:vimtex = b:vimtex_tmp
        unlet b:vimtex_tmp
      else
        unlet b:vimtex
      endif
    endif
  endif
endfunction

" }}}1


" {{{1 Initialize module

" Define list of vimtex modules
if !exists('s:modules')
  let s:modules = map(
        \ split(
        \   globpath(
        \     fnamemodify(expand('<sfile>'), ':r'),
        \     '*.vim'),
        \   '\n'),
        \ 'fnamemodify(v:val, '':t:r'')')
endif

" }}}1

" vim: fdm=marker sw=2
