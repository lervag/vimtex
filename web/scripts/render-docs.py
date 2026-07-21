#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.14"
# dependencies = ["pygments==2.20"]
# ///
"""Render doc/vimtex.txt to a standalone HTML page under <outdir>.

Pipeline:
  1. Fetch neovim's gen_help_html.lua (matching the local neovim).
  2. Run it (headless neovim) to produce a neovim.io HTML fragment.
  3. Strip the fragment's front-matter and rewrite its self-links.
  4. Tidy code blocks (class attribute, padding/doubled newlines).
  5. Link core |tags| to neovim.io and syntax-highlight code with Pygments.
  6. Wrap in a standalone skeleton; write index.html + shared.css + docs.css + pygments.css.

Usage: render-docs.py <outdir>      (run via `uv run`, which supplies Pygments)

Environment:
  NVIM          neovim executable (default: nvim)
  GEN_HELP_REF  git ref of neovim to fetch gen_help_html.lua from; defaults to a
                tag matching the local neovim (or `master` for -dev builds) so
                the Lua and the nvim APIs it calls agree.
"""

from __future__ import annotations

import html
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path
from urllib.parse import quote

from pygments import highlight
from pygments.formatters import HtmlFormatter
from pygments.lexer import inherit
from pygments.lexers import get_lexer_by_name
from pygments.lexers.special import TextLexer
from pygments.lexers.textedit import VimLexer
from pygments.token import Keyword
from pygments.util import ClassNotFound

SCRIPT_DIR = Path(__file__).resolve().parent
WEB_DIR = SCRIPT_DIR.parent
REPO_ROOT = WEB_DIR.parent
DOC_SRC = REPO_ROOT / "doc" / "vimtex.txt"
NVIM = os.environ.get("NVIM", "nvim")

HEAD = """<!DOCTYPE html>
<html lang="en-GB">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>VimTeX documentation</title>
<meta name="description" content="Documentation for VimTeX, a modern Vim/Neovim filetype and syntax plugin for LaTeX.">
<link rel="stylesheet" href="shared.css">
<link rel="stylesheet" href="docs.css">
<link rel="stylesheet" href="pygments.css">
</head>
<body>
<header class="topbar">
  <div class="topbar-inner">
    <a class="back" href="../">VimTeX</a>
    <span class="topbar-note">rendered with <a href="https://raw.githubusercontent.com/neovim/neovim/refs/heads/master/src/gen/gen_help_html.lua">gen_help_html.lua</a></span>
  </div>
</header>
<main class="help-body">
"""

FOOT = """</main>
</body>
</html>
"""


def log(msg: str) -> None:
    print(f"==> render-docs: {msg}", file=sys.stderr)


def die(msg: str):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def nvim_capture(*args: str) -> subprocess.CompletedProcess:
    """Run neovim, capturing stdout+stderr merged as text."""
    return subprocess.run(
        [NVIM, *args], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
    )


def lua_str(s: str) -> str:
    """Quote a path as a Lua single-quoted string literal."""
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def gen_help_ref() -> str:
    """Pick a gen_help_html.lua ref matching the running neovim."""
    line = subprocess.run(
        [NVIM, "--version"], capture_output=True, text=True
    ).stdout.splitlines()[0]
    if "dev" in line:
        default = "master"
    else:
        ver = re.sub(r"[^0-9.].*", "", re.sub(r"^NVIM v", "", line))
        default = f"v{ver}"
    ref = os.environ.get("GEN_HELP_REF", default)
    log(f"neovim '{line}', gen_help_html.lua ref '{ref}'")
    return ref


def fetch_gen_help(ref: str, dest: Path) -> str:
    url = f"https://raw.githubusercontent.com/neovim/neovim/{ref}/src/gen/gen_help_html.lua"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            text = resp.read().decode("utf-8")
    except Exception as exc:  # noqa: BLE001
        die(f"could not download gen_help_html.lua from {url}: {exc}")
    dest.write_text(text, encoding="utf-8")
    return text


def run_generator(lua_text: str, lua_path: Path, doc_dir: Path, out_dir: Path) -> None:
    """Invoke gen_help_html.lua via headless neovim to produce the fragment."""
    # The gen() signature changed across neovim versions: newer builds prepend an
    # `output_format` argument (gen('html', help_dir, ...)); older ones start with
    # help_dir. Detect which the fetched module uses.
    inc = "{ 'vimtex.txt' }"
    args = f"{lua_str(str(doc_dir))}, {lua_str(str(out_dir))}, {inc}"
    if re.search(r"function M\.gen\(\s*output_format", lua_text):
        gen_call = f"m.gen('html', {args})"
    else:
        gen_call = f"m.gen({args})"

    run_lua = "\n".join(
        [
            f"vim.cmd('helptags ' .. vim.fn.fnameescape({lua_str(str(doc_dir))}))",
            f"local mod = assert(loadfile({lua_str(str(lua_path))}), 'failed to load gen_help_html.lua')",
            "local m = mod()",
            f"local r = {gen_call}",
            "print('GEN_ERR_COUNT=' .. tostring(r and r.err_count))",
            "if r and r.err_count and r.err_count > 0 then os.exit(1) end",
        ]
    )
    run_path = lua_path.with_name("run.lua")
    run_path.write_text(run_lua, encoding="utf-8")

    proc = nvim_capture("--headless", "-u", "NONE", "-l", str(run_path))
    if proc.returncode != 0:
        sys.stderr.write("\n".join(proc.stdout.splitlines()[-30:]) + "\n")
        die("gen_help_html.lua failed (parse errors or bad links)")
    for line in proc.stdout.splitlines():
        if line.startswith("GEN_ERR_COUNT"):
            log(line)


# --- fragment post-processing -------------------------------------------------


def strip_frontmatter_and_links(fragment: str) -> str:
    """Drop the JSON front-matter (keep from the first line starting with '<')
    and rewrite neovim.io's absolute self-links into same-page anchors."""
    lines = fragment.splitlines(keepends=True)
    start = next((i for i, ln in enumerate(lines) if ln.startswith("<")), len(lines))
    body = "".join(lines[start:])
    return body.replace('href="/doc/user/vimtex/#', 'href="#')


def _tidy_code(code: str) -> str:
    """Trim leading/trailing newlines and halve internal newline runs (gen doubles
    every source newline)."""
    code = re.sub(r"\A\n+", "", code)
    code = re.sub(r"\n+\Z", "", code)
    return re.sub(r"\n+", lambda m: "\n" * (len(m.group(0)) // 2 or 1), code)


def tidy_code_blocks(body: str) -> str:
    """Normalise both <pre><code ...> (language) and bare <pre> (plain >) blocks."""

    def repl(m: re.Match) -> str:
        inner = m.group(1)
        cm = re.match(r"\A<code([^>]*)>(.*)</code>\Z", inner, re.S)
        if cm:
            attr = re.sub(r" $", "", re.sub(r"\s+", " ", cm.group(1)))
            return f"<pre><code{attr}>{_tidy_code(cm.group(2))}</code></pre>"
        return f"<pre>{_tidy_code(inner)}</pre>"

    return re.sub(r"<pre>(.*?)</pre>", repl, body, flags=re.S)


def load_tagmap() -> dict[str, str]:
    """Map core Vim/Neovim help tags -> help-file basename, from the running
    neovim's tag index ($VIMRUNTIME/doc/tags)."""
    out = nvim_capture("--headless", "-u", "NONE", "-c", "echo $VIMRUNTIME", "-c", "qa").stdout
    runtime = next((ln.strip() for ln in out.splitlines() if "/" in ln), "")
    tags = Path(runtime) / "doc" / "tags" if runtime else None
    if not tags or not tags.is_file():
        log(f"no tags index at {tags} (skipping tag links)")
        return {}
    tagmap: dict[str, str] = {}
    with tags.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            cols = line.rstrip("\n").split("\t")
            if len(cols) >= 2 and cols[1].endswith(".txt"):
                tagmap[cols[0]] = cols[1][:-4]
    return tagmap


def link_core_tags(text: str, tagmap: dict[str, str]) -> str:
    """gen_help_html leaves unresolved |tag| references as literal text; link the
    ones that exist in neovim's docs. The fragment is encoded exactly like
    gen_help_html's url_encode (== quote with safe="()'")."""

    def repl(m: re.Match) -> str:
        page = tagmap.get(html.unescape(m.group(1)))
        if not page:
            return m.group(0)
        frag = quote(html.unescape(m.group(1)), safe="()'")
        return (
            f'<a class="ext-tag" '
            f'href="https://neovim.io/doc/user/{page}.html#{frag}">{m.group(1)}</a>'
        )

    return re.sub(r"\|([^|<>]+?)\|", repl, text)


_FMT = HtmlFormatter(nowrap=True)


class _VimLexerPlus(VimLexer):
    """Pygments' VimLexer omits several common Ex commands (augroup, autocmd,
    echo, execute, normal, command, source, runtime, the :map family, ...); add
    them (with frequent abbreviations) so they highlight as keywords."""

    _extra = (
        r"aug(?:roup)?|au(?:tocmd)?|echo(?:msg|hl|err)?|exe(?:cute)?|"
        r"norm(?:al)?|command|source|runtime|[nvxsoict]?(?:nore)?map"
    )
    tokens = {"root": [(r"\b(?:%s)\b" % _extra, Keyword), inherit]}


_VIM_LEXER = _VimLexerPlus()


def highlight_block(block: str) -> str:
    m = re.match(
        r'<pre><code class="language-([^"]*)"[^>]*>(.*)</code></pre>\Z', block, re.S
    )
    if not m:
        return block  # bare <pre> (plain >): leave as preformatted text
    try:
        lexer = get_lexer_by_name(m.group(1).strip())
    except ClassNotFound:
        lexer = TextLexer()
    if isinstance(lexer, VimLexer):
        lexer = _VIM_LEXER
    inner = highlight(html.unescape(m.group(2)), lexer, _FMT).rstrip("\n")
    return f'<pre class="highlight"><code>{inner}</code></pre>'


def convert_inline_code(text: str) -> str:
    """Convert leftover `codespans` to <code>. gen_help_html handles most, but
    misses adjacent ones (e.g. `a`/`b`/`c`), leaving literal backticks."""
    return re.sub(r"`([^`<>\n]+)`", r"<code>\1</code>", text)


def linkify_and_highlight(body: str, tagmap: dict[str, str]) -> tuple[str, int]:
    """Split on whole <pre>…</pre> blocks; process prose, highlight code."""
    n = 0
    parts = re.split(r"(<pre>.*?</pre>)", body, flags=re.S)
    for i, part in enumerate(parts):
        if i % 2:
            new = highlight_block(part)
            n += new != part
            parts[i] = new
        else:
            part = convert_inline_code(part)
            if tagmap:
                part = link_core_tags(part, tagmap)
            parts[i] = part
    return "".join(parts), n


def _visible_len(html_line: str) -> int:
    return len(html.unescape(re.sub(r"<[^>]+>", "", html_line)))


def reflow_prose(body: str) -> str:
    """Join the help file's soft-wrapped prose lines (it hard-wraps at ~78
    columns) so paragraphs reflow to the container width, while keeping the
    breaks of column-aligned content (contents list, option/tag definitions,
    tables) and code. Works at the line level, so it also reflows prose that
    gen_help_html bundled into a mixed div with a heading or a code block.

    A line break is kept ("hard") when the preceding line: has a run of 3+ spaces
    (column alignment); is short (< 55 visible chars → an intentional break such
    as an option name or a paragraph's last line); or ends a block element."""
    def strip_indent(line: str) -> str:
        # Drop the help file's leading indent so prose paragraphs are flush-left,
        # but leave column-aligned lines (3+ space run) untouched.
        if re.search(r"   ", re.sub(r"<[^>]+>", "", line)):
            return line
        return re.sub(r"^((?:<[^>]+>)*)[ \t]+", r"\1", line)

    # Match <pre> with any attributes: by now code blocks are <pre class="highlight">.
    parts = re.split(r"(<pre\b[^>]*>.*?</pre>)", body, flags=re.S)
    for idx in range(0, len(parts), 2):  # even indices = outside <pre>
        lines = parts[idx].split("\n")
        out: list[str] = []
        for line in lines:
            if out:
                prev = out[-1]
                hard = (
                    re.search(r"   ", re.sub(r"<[^>]+>", "", prev))
                    or _visible_len(prev) < 55
                    or prev.rstrip().endswith(("</div>", "<br>", "</pre>", "</h2>", "</h3>"))
                )
                if not hard:
                    out[-1] = prev + " " + line.lstrip(" ")
                    continue
            out.append(strip_indent(line))
        parts[idx] = "\n".join(out)
    return "".join(parts)


def pygments_css() -> str:
    sel = ".highlight"

    def defs(style: str) -> str:
        raw = HtmlFormatter(style=style).get_style_defs(sel)
        # keep only scoped ".highlight .token" rules; drop the base background
        # rule and any unscoped rules Pygments emits (pre{}, linenos).
        rules = "\n".join(
            ln
            for ln in raw.splitlines()
            if ln.startswith(sel) and not re.match(re.escape(sel) + r"\s*\{", ln)
        )
        # Apply the same token colours to Hugo's Chroma output (.chroma) on the
        # landing page, so both pages share one highlighting style. Chroma is a
        # Pygments port and uses the same token class names.
        return rules + "\n" + rules.replace(sel, ".chroma")

    light_style = "solarized-light"
    light = defs(light_style)
    dark, dark_style = "", ""
    for cand in ("solarized-dark", "github-dark", "monokai"):
        try:
            dark, dark_style = defs(cand), cand
            break
        except ClassNotFound:
            continue
    return (
        f"/* Pygments token colours (light={light_style}, dark={dark_style}). */\n"
        f"{light}\n\n@media (prefers-color-scheme: dark) {{\n{dark}\n}}\n"
    )


def main() -> None:
    if len(sys.argv) != 2:
        die("usage: render-docs.py <outdir>")
    outdir = Path(sys.argv[1])
    if not DOC_SRC.is_file():
        die(f"{DOC_SRC} not found")

    ref = gen_help_ref()

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        doc_dir, out_dir = tmp / "doc", tmp / "out"
        doc_dir.mkdir()
        out_dir.mkdir()
        (doc_dir / "vimtex.txt").write_bytes(DOC_SRC.read_bytes())

        lua_path = tmp / "gen_help_html.lua"
        lua_text = fetch_gen_help(ref, lua_path)
        run_generator(lua_text, lua_path, doc_dir, out_dir)

        fragment_path = out_dir / "vimtex.html"
        if not fragment_path.is_file() or fragment_path.stat().st_size == 0:
            die("generator produced no output")
        fragment = fragment_path.read_text(encoding="utf-8")

    body = strip_frontmatter_and_links(fragment)
    # Drop the <br> gen_help_html adds after a right-aligned tag; the following
    # newline already breaks the line, so the <br> only adds a blank line.
    body = re.sub(
        r'(class="help-tag-right"[^>]*>(?:(?!</span>).)*</span>)<br>', r"\1", body
    )
    body = tidy_code_blocks(body)
    body, n = linkify_and_highlight(body, load_tagmap())
    body = reflow_prose(body)

    outdir.mkdir(parents=True, exist_ok=True)
    for asset in ("shared.css", "docs.css", "arrow-left.svg"):
        (outdir / asset).write_bytes((WEB_DIR / "assets" / asset).read_bytes())
    (outdir / "pygments.css").write_text(pygments_css(), encoding="utf-8")
    index = outdir / "index.html"
    index.write_text(HEAD + body + FOOT, encoding="utf-8")

    log(f"highlighted {n} code blocks")
    log(f"wrote {index} ({index.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
