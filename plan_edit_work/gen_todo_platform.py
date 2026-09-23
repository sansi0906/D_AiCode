# -*- coding: utf-8 -*-
"""生成《平台主体小程序上架待办清单》文档"""
from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn

PATH = r'E:\DAI\平台主体小程序上架待办清单.docx'
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
P('平台主体 小程序上架待办清单', size=22, bold=True, font_cn='黑体', align=WD_ALIGN_PARAGRAPH.CENTER, space_before=70, space_after=6)
P('单一平台主体 · 自营服务与平台撮合同主体承载 · 不涉及医疗', size=12, align=WD_ALIGN_PARAGRAPH.CENTER, space_after=30)
add_table(
    ['项目', '内容'],
    [
        ['运营主体', '平台主体（××生活服务有限公司／××网络科技有限公司），单一主体'],
        ['经营范围', '已按《生活服务小程序-营业执照经营范围方案》单平台主体版核定'],
        ['业务范围', '家政、维修、装修、自建房、居家养老、适老改造、食品（自营与平台撮合均由该主体承载）'],
        ['文档版本', 'V2.0（单平台主体版）'],
        ['编制日期', '××××年××月××日'],
    ],
    widths=[3.5, 12.0],
)
doc.add_page_break()

# ============ 一、待办清单总览 ============
H1('一、待办清单总览')
P('以下为平台主体（单一主体）从营业执照确认后到小程序发布上架的完整待办事项，主线事项按执行顺序编号，支线事项可并行。全部业务资质、证照均以该平台主体名义办理。')
add_table(
    ['序号', '事项', '说明', '预计周期', '卡上架'],
    [
        ['1', '平台主体营业执照注册与经营范围核定', '单平台主体方案已确认；经营范围按核定文本完成注册', '1～3个工作日', '是'],
        ['2', '增值电信业务评估（经营性ICP）', '平台对入驻服务商收取佣金/信息服务费需评估；如需办证周期最长', '咨询数天；办证数月', '是'],
        ['3', '小程序账号注册', '用平台主体营业执照注册；需对公账户打款验证', '当天～1周', '是'],
        ['4', '微信认证', '认证主体与营业执照一致；费用300元/年', '1～3个工作日', '是'],
        ['5', '小程序备案', '平台初审＋属地管局审核；获备案号后在小程序内展示', '数个工作日', '是'],
        ['6', '类目选择与资质准备', '家政/维修/养老→生活服务类；装修→房地产服务类；食品→商家自营类；资质均以平台主体名义提供', '随提审', '是'],
        ['7', '提审材料准备', '类目资质、隐私政策、用户协议、服务商入驻协议、商业模式说明、完整体验版', '1～2周', '是'],
        ['8', '提交审核', '平台审核，可能按驳回意见修改后重提', '数天～数周', '是'],
        ['9', '发布上线', '审核通过后发布；确保备案号展示', '当天', '是'],
    ],
    widths=[1.0, 3.2, 6.2, 2.6, 1.6],
)
P('', space_after=0)
H2('并行支线（不占主线序号）')
add_table(
    ['序号', '事项', '说明', '预计周期', '卡点'],
    [
        ['P1', '银行对公账户开立', '主体注册后即办；小程序账号注册打款验证需要', '3～7个工作日', '支撑事项3'],
        ['P2', '微信支付服务商资质申请', '平台分账结算必需；需公司资质与业务模式材料', '1～2周', '经营必需'],
        ['P3', '域名ICP备案＋SSL（自建方案）', '自建服务器需提前启动；微信云开发可免', '7～20天', '技术必需'],
        ['P4', '食品证照/备案', '以平台主体名义办理：仅预包装食品走备案；经营一般食品需《食品经营许可证》', '备案数天；许可2～4周', '涉食品时卡类目'],
        ['P5', '协议体系', '用户协议、隐私政策、隐私保护指引、服务商入驻协议', '约1周', '卡提审'],
    ],
    widths=[1.0, 3.2, 6.2, 2.6, 1.6],
)

# ============ 二、依赖关系 ============
H1('二、依赖关系')
P('主线串行链：', bold=True)
P('1 营业执照 → 3 账号注册 → 4 微信认证 → 5 备案 → 7 提审材料 → 8 提交审核 → 9 发布', bold=True, align=WD_ALIGN_PARAGRAPH.CENTER)
P('', space_after=0)
H2('关键依赖说明')
add_table(
    ['事项', '前置依赖', '可并行项', '对后续的影响'],
    [
        ['1 营业执照', '经营范围方案（已确认）', '2 增值电信评估', '一切事项的前提'],
        ['2 增值电信评估', '主体、业务模式', '1 营业执照', '平台收费前必须；影响提审商业模式说明'],
        ['3 账号注册', '1 营业执照、P1 对公账户', '6 类目准备', '主线第2步'],
        ['4 微信认证', '3 账号注册', 'P2/P3/P5', '主线第3步'],
        ['5 小程序备案', '3 账号注册、4 微信认证', 'P2/P3/P4/P5', '主线第4步；获备案号'],
        ['6 类目资质', '1 经营范围、P4 食品证照（如涉）', '3～5 主线', '卡提审材料'],
        ['7 提审材料', '4 认证、5 备案、6 类目、P5 协议、P3 域名', '—', '卡提交审核'],
        ['8 提交审核', '7 提审材料', '—', '卡发布'],
        ['9 发布上线', '8 审核通过', '—', '目标完成'],
    ],
    widths=[2.6, 4.2, 3.2, 4.6],
)

# ============ 三、关键路径与排期 ============
H1('三、关键路径与建议排期')
P('关键路径（决定整体时长）：1 营业执照 → 3 账号注册 → 4 认证 → 5 备案 → 7 提审材料 → 8 审核 → 9 发布。')
bullet('全部业务与证照均挂靠平台主体单一主体：增值电信、食品、装修施工资质按各自业务分别办理，互不豁免。')
bullet('若采用自建服务器：P3 域名备案（7～20天）为最长支线，建议与主线同步启动，最迟在事项7前完成。')
bullet('若平台对服务商收费：事项2（增值电信）是最长前置，需最早启动；办证期间不影响开发，但影响上线节奏。')
P('', space_after=0)
add_table(
    ['时间', '主线动作', '并行动作'],
    [
        ['第1周', '1 主体注册与经营范围核定', '2 增值电信评估启动；P1 对公账户'],
        ['第1～2周', '3 账号注册；4 认证提交', 'P3 域名备案启动；P5 协议起草'],
        ['第2～3周', '5 备案提交', 'P2 服务商资质申请；P4 食品证照（如涉）'],
        ['第3～4周', '6 类目申请；7 提审材料', '体验版走查与完善'],
        ['第4～5周', '8 提交审核；9 发布', '上线前自检'],
    ],
    widths=[2.6, 6.2, 5.8],
)

doc.save(PATH)
print('GEN_OK')
