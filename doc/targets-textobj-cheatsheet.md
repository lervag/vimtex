# A cheatsheet for vimtex-targets

If [targets.vim](https://github.com/wellle/targets.vim) is installed next to
vimtex and `g:vimtex_text_obj_variant != 'vimtex'`, the following extended text
objects are available.

### Legend

```
cursor position │    .....................
buffer line     │    This is example text \emph{with a \latex\ command}.
selection       │                               └──────── inc ───────┘
```

## Commands

Available mappings

```
     ic  ac  Ic  Ac
    inc anc Inc Anc
    ilc alc Ilc Alc
```

Chart for a list of commands

```
                                     ..............
a \cmd{ bbbbbbbb }  \cmd{ ccccccc }  \cmd{ dddddd }  \cmd{ eeeeeee } \cmd{ ffffffff }
  │    │└ 2Ilc ┘││ ││    │└ Ilc ┘││ ││    │└ Ic ┘││ ││    │└ Inc ┘││││    │└ 2Inc ┘││
  │    └─ 2ilc ─┘│ ││    └─ ilc ─┘│ ││    └─ ic ─┘│ ││    └─ inc ─┘│││    └─ 2inc ─┘│
  ├────── 2alc ──┘ │├────── alc ──┘ │├────── ac ──┘ │├────── anc ──┘│└────── 2anc ──┤
  └────── 2Alc ────┘└────── Alc ────┘└────── Ac ────┘└────── Anc ───┤               │
                                                                    └─────── 2Anc ──┘
```

Chart for nested commands

```
                                       ..............
a \cmd{ b \cmd{ cccccccc } d } \cmd{ e \cmd{ ffffff } g } \cmd{ h \cmd{ iiiiiiii }j }
  │    ││ │    │└ 2Ilc ┘││││││││    ││ │    │└ Ic ┘││││││││    ││││    │└ 2Inc ┘│││││
  │    ││ │    └─ 2ilc ─┘│││││││    ││ │    └─ ic ─┘│││││││    ││││    └─ 2inc ─┘││││
  │    ││ ├────── 2alc ──┘││││││    ││ ├────── ac ──┘││││││    │││└────── 2anc ──┤│││
  │    ││ └────── 2Alc ───┘│││││    ││ └────── Ac ───┘│││││    ││└─────── 2Anc ──┘│││
  │    │└───────── Ilc ────┘││││    │└─────── 2Ic ────┘││││    │└───────── Inc ───┘││
  │    └────────── ilc ─────┘│││    └──────── 2ic ─────┘│││    └────────── inc ────┘│
  ├─────────────── alc ──────┘│├───────────── 2ac ──────┘│└─────────────── anc ─────┤
  └─────────────── Alc ───────┘└───────────── 2Ac ───────┤                          │
                                                         └──────────────── Anc ─────┘
```


## Environments

Available mappings

```
     ie  ae  Ie  Ae
    ine ane Ine Ane
    ile ale Ile Ale
```

Chart for list of environments

```
 \begin{A} ────────────┬────┐
           ───────┐    │    │
   a       ──┐    │    │    │
   a        2Ile 2ile 2ale 2Ale
   a       ──┘    │    │    │
           ───────┘    │    │
 \end{A}   ────────────┘    │
           ─────────────────┘
 \begin{B} ─────────┬───┐
           ─────┐   │   │
   b       ─┐   │   │   │
   b        Ile ile ale Ale
   b       ─┘   │   │   │
           ─────┘   │   │
 \end{B}   ─────────┘   │
           ─────────────┘
.\begin{C} ───────┬──┐
.          ────┐  │  │
.  c       ─┐  │  │  │
.  c        Ie ie ae Ae
.  c       ─┘  │  │  │
.          ────┘  │  │
.\end{C}   ───────┘  │
           ──────────┘
 \begin{D} ─────────┬───┐
           ─────┐   │   │
   d       ─┐   │   │   │
   d        Ine ine ane Ane
   d       ─┘   │   │   │
           ─────┘   │   │
 \end{D}   ─────────┘   │
           ─────────────┴───┐
 \begin{E} ────────────┐    │
           ───────┐    │    │
   e       ──┐    │    │    │
   e        2Ine 2ine 2ane 2Ane
   e       ──┘    │    │    │
           ───────┘    │    │
 \end{E}   ────────────┴────┘
```

Chart for nested environments

```
 \begin{A}      ────────────────────────────┬───┐
                ────────────────────────┐   │   │
     a          ────────────────────┐   │   │   │
                                    │   │   │   │
     \begin{B}  ───────────┬────┐   │   │   │   │
                ──────┐    │    │   │   │   │   │
     b          ─┐    │    │    │   │   │   │   │
     b          2Ile 2ile 2ale 2Ale Ile ile ale Ale
     b          ─┘    │    │    │   │   │   │   │
                ──────┘    │    │   │   │   │   │
     \end{B}    ───────────┘    │   │   │   │   │
                ────────────────┘   │   │   │   │
     a          ────────────────────┘   │   │   │
                ────────────────────────┘   │   │
 \end{A}        ────────────────────────────┘   │
                ────────────────────────────────┘
 \begin{C}      ──────────────────────┬───┐
                ──────────────────┐   │   │
     c          ──────────────┐   │   │   │
                              │   │   │   │
.    \begin{D}  ───────┬──┐   │   │   │   │
.               ────┐  │  │   │   │   │   │
.    d          ─┐  │  │  │   │   │   │   │
.    d           Ie ie ae Ae 2Ie 2ie 2ae 2Ae
.    d          ─┘  │  │  │   │   │   │   │
.               ────┘  │  │   │   │   │   │
.    \end{D}    ───────┘  │   │   │   │   │
                ──────────┘   │   │   │   │
     c          ──────────────┘   │   │   │
                ──────────────────┘   │   │
 \end{C}        ──────────────────────┘   │
                ──────────────────────────┴──────┐
 \begin{E}      ─────────────────────────────┐   │
                ─────────────────────────┐   │   │
     e          ─────────────────────┐   │   │   │
                                     │   │   │   │
     \begin{F}  ────────────┬────┐   │   │   │   │
                ───────┐    │    │   │   │   │   │
     f          ──┐    │    │    │   │   │   │   │
     f           2Ine 2ine 2ane 2Ane Ine ine ane Ane
     f          ──┘    │    │    │   │   │   │   │
                ───────┘    │    │   │   │   │   │
     \end{F}    ────────────┘    │   │   │   │   │
                ─────────────────┘   │   │   │   │
     e          ─────────────────────┘   │   │   │
                ─────────────────────────┘   │   │
 \end{E}        ─────────────────────────────┴───┘
```
