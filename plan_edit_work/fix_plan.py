# -*- coding: utf-8 -*-
"""修复精简后文档的四处问题"""
import re
from docx import Document
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

PATH = r'E:\DAI\生活服务小程序上架方案.docx'
doc = Document(PATH)
body = doc.element.body


def ptext(el):
    return ''.join(t.text or '' for t in el.iter(qn('w:t')))


def set_para_text(p_el, text):
    runs = p_el.findall(qn('w:r'))
    for i, r in enumerate(runs):
        for t in r.findall(qn('w:t')):
            r.remove(t)
        if i == 0:
            t = OxmlElement('w:t'); t.set(qn('xml:space'), 'preserve'); t.text = text
            r.append(t)


paras = list(doc.paragraphs)

# ---------- 1. 子标题编号后补空格 + 10.5 改名 ----------
for p in paras:
    if p.style.name == 'Heading 2':
        t = p.text.strip()
        m = re.match(r'^(\d+\.\d+)([^\s])', t)
        if m:
            set_para_text(p._element, m.group(1) + ' ' + t[m.end(1):])
        elif t.startswith('10.5') and '材料准备' not in t:
            set_para_text(p._element, '10.5 提审材料准备')

# ---------- 2. 删除 9.3 灰度发布（H2 + 其后段落） ----------
h9_3 = None
for p in paras:
    if p.style.name == 'Heading 2' and p.text.strip().startswith('9.3'):
        h9_3 = p._element
        break
if h9_3 is not None:
    nxt = h9_3.getnext()
    body.remove(h9_3)
    while nxt is not None:
        if nxt.tag == qn('w:p'):
            pPr = nxt.find(qn('w:pPr'))
            if pPr is not None:
                s = pPr.find(qn('w:pStyle'))
                if s is not None and s.get(qn('w:val')) in ('Heading1', 'Heading 1', '3'):
                    break
        n2 = nxt.getnext()
        body.remove(nxt)
        nxt = n2

# ---------- 3. 修复第六章内容顺序 ----------
h6 = h7 = None
for p in paras:
    if p.style.name == 'Heading 1' and '\t' not in p.text:
        t = p.text.strip()
        if t.startswith('六、账号与开发环境准备'):
            h6 = p._element
        elif t.startswith('七、提审材料准备'):
            h7 = p._element
            break

# 收集 h6 与 h7 之间的元素
between = []
el = h6.getnext()
while el is not None and el is not h7:
    between.append(el)
    el = el.getnext()

# 识别 h2_6.1 与三个 bullet
h2_61 = None
bullets = []
for b in between:
    txt = ptext(b).strip()
    if b.tag == qn('w:p') and b.find(qn('w:pPr')) is not None:
        s = b.find(qn('w:pPr')).find(qn('w:pStyle'))
        if s is not None and txt.startswith('6.1'):
            h2_61 = b
            continue
    if txt.startswith('小程序AppID'):
        bullets.append(('b1', b))
    elif txt.startswith('微信支付商户号'):
        bullets.append(('b2', b))
    elif txt.startswith('后台管理端'):
        bullets.append(('b3', b))

for b in between:
    body.remove(b)

# 按正确顺序重插：h2_61, b1, b2, b3
ordered = []
if h2_61 is not None:
    ordered.append(h2_61)
for key in ('b1', 'b2', 'b3'):
    for k, el in bullets:
        if k == key:
            ordered.append(el)
for el in ordered:
    h7.addprevious(el)

doc.save(PATH)
print('FIX_OK')
