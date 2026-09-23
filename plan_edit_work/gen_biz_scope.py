# -*- coding: utf-8 -*-
"""生成《生活服务小程序-营业执照经营范围方案》——单平台主体版"""
from docx import Document
from docx.shared import Pt, Cm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn

PATH = r'E:\DAI\生活服务小程序-营业执照经营范围方案.docx'
doc = Document()

sec = doc.sections[0]
sec.page_width, sec.page_height = Cm(21.0), Cm(29.7)
sec.top_margin = sec.bottom_margin = Cm(2.3)
sec.left_margin = sec.right_margin = Cm(2.5)

normal = doc.styles['Normal']
normal.font.name = 'Times New Roman'
normal.font.size = Pt(11)
normal._element.rPr.rFonts.set(qn('w:eastAsia'), '宋体')


def set_run(run, font_cn='宋体', font_en='Times New Roman', size=11, bold=False):
    run.font.name = font_en
    run.font.size = Pt(size)
    run.font.bold = bold
    run._element.rPr.rFonts.set(qn('w:eastAsia'), font_cn)


def P(text, size=11, bold=False, font_cn='宋体', align=None, space_before=0, space_after=6):
    p = doc.add_paragraph()
    if align is not None:
        p.alignment = align
    pf = p.paragraph_format
    pf.space_before = Pt(space_before)
    pf.space_after = Pt(space_after)
    r = p.add_run(text)
    set_run(r, font_cn=font_cn, size=size, bold=bold)
    return p


def H1(text):
    return P(text, size=15, bold=True, font_cn='黑体', space_before=14, space_after=8)


def H2(text):
    return P(text, size=12.5, bold=True, font_cn='黑体', space_before=10, space_after=6)


def bullet(text, size=11):
    p = doc.add_paragraph()
    pf = p.paragraph_format
    pf.space_after = Pt(3)
    pf.left_indent = Pt(18)
    r = p.add_run(text)
    set_run(r, size=size)
    return p


def set_cell(cell, text, bold=False, size=10.5, align_center=False):
    cell.text = ''
    p = cell.paragraphs[0]
    if align_center:
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    pf = p.paragraph_format
    pf.space_after = Pt(2)
    pf.space_before = Pt(2)
    r = p.add_run(text)
    set_run(r, size=size, bold=bold)


def add_table(headers, rows, widths=None):
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = 'Table Grid'
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    for j, h in enumerate(headers):
        set_cell(t.rows[0].cells[j], h, bold=True, align_center=True)
    for i, row in enumerate(rows):
        for j, v in enumerate(row):
            set_cell(t.rows[i + 1].cells[j], v)
    if widths:
        for j, w in enumerate(widths):
            for row in t.rows:
                row.cells[j].width = Cm(w)
    return t


# ============ 封面 ============
P('生活服务小程序', size=22, bold=True, font_cn='黑体', align=WD_ALIGN_PARAGRAPH.CENTER, space_before=60, space_after=6)
P('营业执照经营范围方案', size=18, bold=True, font_cn='黑体', align=WD_ALIGN_PARAGRAPH.CENTER, space_after=4)
P('—— 单平台主体注册方案（自营服务与平台撮合同主体承载）——', size=11, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=30)
add_table(
    ['项目', '内容'],
    [
        ['适用业务', '家政、维修、装修、自建房、居家养老、适老改造、食品'],
        ['运营模式', '自营＋平台撮合，由单一平台主体承载'],
        ['医疗边界', '不涉及医疗服务'],
        ['文档版本', 'V2.0（单平台主体版）'],
        ['编制日期', '××××年××月××日'],
    ],
    widths=[3.5, 12.0],
)
doc.add_page_break()

# ============ 一、京东、美团参考 ============
H1('一、京东、美团生活服务相关经营范围参考')
P('以下摘录自国家企业信用信息公示系统公开的工商登记信息（2026年9月更新），仅取与生活服务相关的条目。')

H2('1.1 京东（北京京东世纪贸易有限公司，信用代码 911103026605015136）')
bullet('安装维修类：专用设备修理；通用设备修理；电子、机械设备维护（不含特种设备）；普通机械设备安装服务；工业机器人安装、维修')
bullet('销售零售类：家用电器销售；五金产品批发；家具销售；建筑装饰材料销售；建筑材料销售；卫生洁具销售')
bullet('居民服务类：居民日常生活服务；物业管理；停车场服务；宠物服务（不含动物诊疗）；劳务服务（不含劳务派遣）；摄影扩印服务')
bullet('食品类：食品销售（仅销售预包装食品）；保健食品（预包装）销售；特殊医学用途配方食品销售；婴幼儿配方乳粉及其他婴幼儿配方食品销售')
bullet('平台技术类：软件开发；技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；信息系统集成服务；社会经济咨询服务；企业管理咨询')
bullet('许可项目：第一类增值电信业务；第二类增值电信业务')

H2('1.2 美团（北京三快在线科技有限公司，信用代码 91110108562144110X）')
bullet('技术平台类：技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；软件开发；软件销售；信息系统集成服务')
bullet('经营服务类：市场营销策划；社会经济咨询服务；供应链管理服务；广告设计、代理；广告制作；广告发布')
bullet('配送物流类：外卖递送服务；国内货物运输代理；普通货物仓储服务')
bullet('零售类：计算机软硬件及辅助设备批发、零售；礼品花卉销售')
bullet('许可项目：第二类增值电信业务；食品销售（2026年1月起由“仅销售预包装食品”放宽为完整许可项）')

H2('1.3 美团集团另一主体（北京三快科技有限公司，信用代码 91110108660511594M）')
bullet('生活服务类：票务代理服务；旅客票务代理；酒店管理；外卖递送服务；互联网销售（除销售需要许可的商品）')
bullet('零售类：日用品销售；五金产品零售；家用电器零配件销售；家具销售；建筑材料销售；食用农产品零售；第一类医疗器械销售')
bullet('许可项目：食品销售；药品零售；第一类、第二类增值电信业务')

H2('1.4 参考要点')
bullet('平台主体是固定套路：技术开发／技术服务 ＋ 软件开发 ＋ 信息系统集成 ＋ 广告 ＋ 增值电信业务 ＋ 食品销售，这是本地生活服务平台的标配表述。')
bullet('家政、养老、维修等具体服务，京东、美团核心主体反而没有直接写入——靠“居民日常生活服务”等兜底表述，具体服务由专业子公司单独承载。')
bullet('食品销售近年成为平台主体标配许可项：仅销售预包装食品可备案（多证合一），经营一般食品需《食品经营许可证》。')

# ============ 二、单平台主体经营范围草案 ============
H1('二、单平台主体经营范围草案')
P('本项目确定采用单一平台主体：自营服务履约与平台撮合均由该主体承载，经营范围将自营业务、平台技术业务与许可项目合并列入。写法参考京东、美团主体，并按业务板块分组，便于登记机关核定。')

H2('一般项目（按板块分组）')
add_table(
    ['板块', '经营范围条目'],
    [
        ['平台技术类', '技术服务、技术开发、技术咨询、技术交流、技术转让、技术推广；软件开发；软件销售；信息系统集成服务'],
        ['经营服务类', '企业营销策划；市场营销策划；社会经济咨询服务；供应链管理服务'],
        ['广告类', '广告设计、代理；广告制作；广告发布'],
        ['居民家政类', '居民日常生活服务；家政服务；家庭服务；劳务服务（不含劳务派遣）'],
        ['维修安装类', '家用电器维修服务；家具安装和维修服务；日用电器修理；通用设备修理；专用设备修理'],
        ['装修类', '住宅室内装饰装修；建筑装饰材料销售；建筑材料销售；五金产品零售；家用电器销售；家具销售；卫生洁具销售'],
        ['养老服务类', '养老服务；居家养老服务；老年人养护服务；助餐、助洁、助浴服务；适老化改造服务'],
        ['零售电商类', '互联网销售（除销售需要许可的商品）；日用品销售；食用农产品零售'],
    ],
    widths=[3.2, 12.3],
)

H2('许可项目')
add_table(
    ['许可项目', '办理方式'],
    [
        ['第一类增值电信业务；第二类增值电信业务', '经营性互联网信息服务（平台对服务商收费撮合），注册前咨询属地通信管理局确认'],
        ['食品销售（仅销售预包装食品）；食品互联网销售（仅销售预包装食品）', '备案制（多证合一）'],
        ['食品销售（经营一般食品）', '先取得《食品经营许可证》'],
        ['建筑装饰装修工程施工（承接整体施工）', '按资质要求取得建筑业企业资质'],
    ],
    widths=[8.0, 7.5],
)

H2('单主体合并说明')
bullet('自营履约与平台撮合同主体承载时，各类许可按各自业务分别办理、互不豁免：平台收费撮合评估增值电信，经营一般食品办《食品经营许可证》，承接整体装修施工办建筑业资质。')
bullet('开锁服务若涉及，需向公安部门备案。')
bullet('经营范围较长，核名与登记时需逐项核对，确保登记系统内置《经营范围规范表述目录》可勾选一致。')

# ============ 三、办理与登记提示 ============
H1('三、办理与登记提示')
P('① 主体名称：建议用“××生活服务有限公司／××网络科技有限公司”，名称行业须与主要经营范围匹配，并体现平台定位。', space_after=4)
P('② 勾选口径：登记时从当地登记系统内置的《经营范围规范表述目录》中勾选，本文条目供对照，最终以登记机关核定为准。', space_after=4)
P('③ 前置许可：仅销售预包装食品走备案（多证合一）；经营一般食品先办《食品经营许可证》；开锁业务向公安部门备案；承接整体装修施工需建筑业资质。', space_after=4)
P('④ 增值电信评估：平台主体若向入驻服务商收取信息服务费或佣金，属于经营性互联网信息服务，建议注册前咨询属地通信管理局是否需要《增值电信业务经营许可证》（经营性ICP）。', space_after=4)
P('⑤ 主体一致性：小程序注册主体、备案主体必须与营业执照主体100%一致，名称与经营范围不得有出入。', space_after=4)

doc.save(PATH)
print('GEN_OK')
