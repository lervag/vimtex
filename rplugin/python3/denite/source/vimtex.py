# -*- coding: utf-8 -*-

from .base import Base


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'vimtex'
        self.kind = 'file'

    @staticmethod
    def format_number(n):
        if not n or not type(n) is dict or n['frontmatter'] or n['backmatter']:
            return ''

        num = [str(n[k]) for k in [
               'part',
               'chapter',
               'section',
               'subsection',
               'subsubsection',
               'subsubsubsection'] if n[k] is not 0]

        if n['appendix']:
            num[0] = chr(int(num[0]) + 64)

        fnum = '.'.join(num)
        return fnum

    @staticmethod
    def create_candidate(e, depth):
        indent = (' ' * 2*(int(depth) - int(e['level'])) + e['title'])[:60]
        number = Source.format_number(e['number'])
        abbr = '{:65}{:10}'.format(indent, number)
        return {'word': e['title'],
                'abbr': abbr,
                'action__path': e['file'],
                'action__line': e.get('line', 0)}

    def gather_candidates(self, context):
        entries = self.vim.eval('vimtex#parser#toc(b:vimtex.tex)')
        depth = max([int(e['level']) for e in entries])
        return [Source.create_candidate(e, depth) for e in entries]
