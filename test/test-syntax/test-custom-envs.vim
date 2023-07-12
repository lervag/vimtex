source common.vim

let g:vimtex_syntax_custom_envs = [
      \ {
      \   'name': 'MyMathEnv',
      \   'math': v:true
      \ },
      \ {
      \   'name': 'python_code',
      \   'region': 'texPythonCodeZone',
      \   'nested': 'python',
      \ },
      \ {
      \   'name': 'code',
      \   'region': 'texCodeZone',
      \   'nested': {
      \     'python': 'language=python',
      \     'c': 'language=C',
      \     'rust': 'language=rust',
      \   },
      \ },
      \]

Edit test-custom-envs.tex

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
