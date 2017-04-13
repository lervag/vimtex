# -*- coding: utf-8 -*-

from .base import Base


class Source(Base):

    def __init__(self, vim):
        super().__init__(vim)

        self.name = 'vimtex_labels'
        self.kind = 'file'

    @staticmethod
    def create_candidate(e):
        return {'word': e['title'],
                'abbr': e['title'][:60],
                'action__path': e['file'],
                'action__line': e.get('line', 0)}

    def gather_candidates(self, context):
        entries = self.vim.eval('vimtex#labels#get_entries()')
        return [Source.create_candidate(e) for e in entries]
