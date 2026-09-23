# -*- coding: utf-8 -*-
"""枚举文档 body 结构"""
from docx import Document
from docx.oxml.ns import qn

doc = Document(r'E:\DAI\生活服务小程序上架准备清单.docx')
body = doc.element.body
for i, el in enumerate(body):
    tag = el.tag.split('}')[-1]
    if tag == 'p':
        texts = ''.join(t.text or '' for t in el.iter(qn('w:t')))
        pPr = el.find(qn('w:pPr'))
        st = ''
        if pPr is not None:
            s = pPr.find(qn('w:pStyle'))
            if s is not None:
                st = s.get(qn('w:val'))
        print(i, 'p', 'st=' + st, repr(texts[:40]))
    elif tag == 'tbl':
        print(i, 'TABLE rows=', len(el.findall(qn('w:tr'))))
    else:
        print(i, tag)
