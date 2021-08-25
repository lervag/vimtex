" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#latexmk#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

function! vimtex#compiler#latexmk#wrap_option(name, value) abort " {{{1
  return has('win32')
        \ ? ' -e "$' . a:name . ' = ''' . a:value . '''"'
        \ : ' -e ''$' . a:name . ' = "' . a:value . '"'''
endfunction

"}}}1
function! vimtex#compiler#latexmk#get_rc_opt(root, opt, type, default) abort " {{{1
  "
  " Parse option from .latexmkrc.
  "
  " Arguments:
  "   root         Root of LaTeX project
  "   opt          Name of options
  "   type         0 if string, 1 if integer, 2 if list
  "   default      Value to return if option not found in latexmkrc file
  "
  " Output:
  "   [value, location]
  "
  "   value        Option value (integer or string)
  "   location     An integer that indicates where option was found
  "                 -1: not found (default value returned)
  "                  0: global latexmkrc file
  "                  1: local latexmkrc file
  "

  if a:type == 0
    let l:pattern = '^\s*\$' . a:opt . '\s*=\s*[''"]\(.\+\)[''"]'
  elseif a:type == 1
    let l:pattern = '^\s*\$' . a:opt . '\s*=\s*\(\d\+\)'
  elseif a:type == 2
    let l:pattern = '^\s*@' . a:opt . '\s*=\s*(\(.*\))'
  else
    throw 'VimTeX: Argument error'
  endif

  " Candidate files
  " - each element is a pair [path_to_file, is_local_rc_file].
  let l:files = [
        \ [a:root . '/latexmkrc', 1],
        \ [a:root . '/.latexmkrc', 1],
        \ [fnamemodify('~/.latexmkrc', ':p'), 0],
        \ [fnamemodify(
        \    !empty($XDG_CONFIG_HOME) ? $XDG_CONFIG_HOME : '~/.config', ':p')
        \    . '/latexmk/latexmkrc', 0]
        \]

  let l:result = [a:default, -1]

  for [l:file, l:is_local] in l:files
    if filereadable(l:file)
      let l:match = matchlist(readfile(l:file), l:pattern)
      if len(l:match) > 1
        let l:result = [l:match[1], l:is_local]
        break
      end
    endif
  endfor

  " Parse the list
  if a:type == 2 && l:result[1] > -1
    let l:array = split(l:result[0], ',')
    let l:result[0] = []
    for l:x in l:array
      let l:x = substitute(l:x, "^'", '', '')
      let l:x = substitute(l:x, "'$", '', '')
      let l:result[0] += [l:x]
    endfor
  endif

  return l:result
endfunction

" }}}1


let s:compiler = vimtex#compiler#_t#new({
      \ 'name' : 'latexmk',
      \ 'executable' : 'latexmk',
      \ 'options' : [
      \   '-verbose',
      \   '-file-line-error',
      \   '-synctex=1',
      \   '-interaction=nonstopmode',
      \ ],
      \ 'callback' : 1,
      \ 'continuous': 1,
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  let l:required = [self.executable]
  if self.continuous && !(has('win32') || has('win32unix'))
    let l:required += ['pgrep']
  endif

  " Check for required executables
  for l:exe in l:required
    if !executable(l:exe)
      call vimtex#log#warning(l:cmd . ' is not executable')
      throw 'VimTeX: Requirements not met'
    endif
  endfor

  " Check option validity
  if self.callback
        \ && !(has('clientserver') || has('nvim') || has('job'))
    call vimtex#log#warning(
          \ 'Can''t use callbacks without +job, +nvim, or +clientserver',
          \ 'Callback option has been disabled.')
    let self.callback = 0
  endif
endfunction

" }}}1

function! s:compiler.__init() abort dict " {{{1
  call self.__init_build_dir()
  call self.__init_pdf_mode()
  unlet self.__init_build_dir
  unlet self.__init_pdf_mode

  let self.__configuration = [
        \ ['executable', self.executable],
        \ ['continuous', self.continuous],
        \ ['callback', self.callback],
        \]
endfunction

" }}}1
function! s:compiler.__init_build_dir() abort dict " {{{1
  " Check if .latexmkrc sets the build_dir - if so this should be respected
  let l:out_dir =
        \ vimtex#compiler#latexmk#get_rc_opt(self.root, 'out_dir', 0, '')[0]
  if !empty(l:out_dir)
    if !empty(self.build_dir) && (self.build_dir !=# l:out_dir)
      call vimtex#log#warning(
            \ 'Setting out_dir from latexmkrc overrides build_dir!',
            \ 'Changed build_dir from: ' . self.build_dir,
            \ 'Changed build_dir to: ' . l:out_dir)
    endif
    let self.build_dir = l:out_dir
  endif
endfunction

" }}}1
function! s:compiler.__init_pdf_mode() abort dict " {{{1
  " If the TeX program directive was not set, and if the pdf_mode is set in
  " a .latexmkrc file, then deduce the compiler engine from the value of
  " pdf_mode.

  " Parse the pdf_mode option. Returns -1 if not found.
  let [l:pdf_mode, l:is_local] =
        \ vimtex#compiler#latexmk#get_rc_opt(self.root, 'pdf_mode', 1, -1)
  if l:pdf_mode < 1 || l:pdf_mode > 5 | return | endif

  let l:tex_program = [
        \ 'pdflatex',
        \ 'pdfps',
        \ 'pdfdvi',
        \ 'lualatex',
        \ 'xelatex',
        \][l:pdf_mode-1]

  " Override self.tex_program if pdf_mode has a supported value and the current
  " TeX program directive in self.tex_program is not specified
  if self.tex_program ==# '_'
    let self.tex_program = l:tex_program
    return
  endif

  " Give warning when there may be a confusing conflict
  if l:is_local && self.tex_program !=# l:tex_program
    call vimtex#log#warning(
          \ 'Value of pdf_mode from latexmkrc is inconsistent with ' .
          \ 'TeX program directive!',
          \ 'TeX program: ' . self.tex_program,
          \ 'pdf_mode:    ' . l:tex_program,
          \ 'The value of pdf_mode will be ignored.')
  endif
endfunction

" }}}1

function! s:compiler.__build_cmd() abort dict " {{{1
  let l:cmd = (has('win32')
        \ ? 'set max_print_line=2000 & '
        \ : 'max_print_line=2000 ') . self.executable

  let l:cmd .= ' ' . join(self.options)
  let l:cmd .= ' ' . self.get_engine()

  if !empty(self.build_dir)
    let l:cmd .= ' -outdir=' . fnameescape(self.build_dir)
  endif

  if self.continuous
    let l:cmd .= ' -pvc'

    " Set viewer options
    if !g:vimtex_view_automatic
          \ || get(get(b:vimtex, 'viewer', {}), 'xwin_id') > 0
          \ || get(s:, 'silence_next_callback', 0)
      let l:cmd .= ' -view=none'
    elseif g:vimtex_view_enabled
          \ && has_key(b:vimtex.viewer, 'latexmk_append_argument')
      let l:cmd .= b:vimtex.viewer.latexmk_append_argument()
    endif

    if self.callback
      if has('job') || has('nvim')
        for [l:opt, l:val] in items({
              \ 'success_cmd' : 'vimtex_compiler_callback_success',
              \ 'failure_cmd' : 'vimtex_compiler_callback_failure',
              \})
          let l:func = 'echo ' . l:val
          let l:cmd .= s:wrap_option_appendcmd(l:opt, l:func)
        endfor
      elseif empty(v:servername)
        call vimtex#log#warning('Can''t use callbacks with empty v:servername')
      else
        " Some notes:
        " - We excape the v:servername because this seems necessary on Windows
        "   for neovim, see e.g. Github Issue #877
        for [l:opt, l:val] in items({'success_cmd' : 1, 'failure_cmd' : 0})
          let l:callback = has('win32')
                \   ? '"vimtex#compiler#callback(' . l:val . ')"'
                \   : '\"vimtex\#compiler\#callback(' . l:val . ')\"'
          let l:func = vimtex#util#shellescape('""')
                \ . g:vimtex_compiler_progname
                \ . vimtex#util#shellescape('""')
                \ . ' --servername ' . vimtex#util#shellescape(v:servername)
                \ . ' --remote-expr ' . l:callback
          let l:cmd .= s:wrap_option_appendcmd(l:opt, l:func)
        endfor
      endif
    endif
  endif

  return l:cmd . ' ' . vimtex#util#shellescape(self.target)
endfunction

" }}}1

function! s:compiler.__pprint_append() abort dict " {{{1
  return [
        \ ['callback', self.callback],
        \ ['continuous', self.continuous],
        \ ['executable', self.executable],
        \]
endfunction

" }}}1


function! s:compiler.clean(full) abort dict " {{{1
  let l:restart = self.is_running()
  if l:restart
    call self.stop()
  endif

  " Define and run the latexmk clean cmd
  let l:cmd = (has('win32')
        \   ? 'cd /D "' . self.root . '" & '
        \   : 'cd ' . vimtex#util#shellescape(self.root) . '; ')
        \ . self.executable . ' ' . (a:full ? '-C ' : '-c ')
  if !empty(self.build_dir)
    let l:cmd .= printf(' -outdir=%s ', fnameescape(self.build_dir))
  endif
  let l:cmd .= vimtex#util#shellescape(self.target)
  call vimtex#process#run(l:cmd)

  call vimtex#log#info('Compiler clean finished' . (a:full ? ' (full)' : ''))

  if l:restart
    let self.silent_next_callback = 1
    silent call self.start()
  endif
endfunction

" }}}1
function! s:compiler.get_engine() abort dict " {{{1
  return get(extend(g:vimtex_compiler_latexmk_engines,
        \ {
        \  'pdfdvi'           : '-pdfdvi',
        \  'pdfps'            : '-pdfps',
        \  'pdflatex'         : '-pdf',
        \  'luatex'           : '-lualatex',
        \  'lualatex'         : '-lualatex',
        \  'xelatex'          : '-xelatex',
        \  'context (pdftex)' : '-pdf -pdflatex=texexec',
        \  'context (luatex)' : '-pdf -pdflatex=context',
        \  'context (xetex)'  : '-pdf -pdflatex=''texexec --xtx''',
        \ }, 'keep'), self.tex_program, '-pdf')
endfunction

" }}}1


function! s:wrap_option_appendcmd(name, value) abort " {{{1
  " Note: On Linux, we use double quoted perl strings; these interpolate
  "       variables. One should therefore NOT pass values that contain `$`.
  let l:win_cmd_sep = has('nvim') ? '^&' : '&'
  let l:common = printf('$%s = ($%s ? $%s', a:name, a:name, a:name)
  return has('win32')
        \ ? printf(' -e "%s . '' %s '' : '''') . ''%s''"',
        \          l:common, l:win_cmd_sep, a:value)
        \ : printf(' -e ''%s . " ; " : "") . "%s"''',
        \          l:common, a:value)
endfunction

"}}}1
