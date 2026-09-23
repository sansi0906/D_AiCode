# -*- coding: utf-8 -*-
"""重建文档：只保留营业执照注册 + 小程序备案内容"""
from docx import Document
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

PATH = r'E:\DAI\生活服务小程序上架准备清单.docx'
doc = Document(PATH)
body = doc.element.body

# ---------- 样式 ID ----------
h1_id = doc.styles['Heading 1'].style_id
h2_id = doc.styles['Heading 2'].style_id
print('h1_id=', h1_id, 'h2_id=', h2_id)


def make_para(text, style_id=None):
    p = OxmlElement('w:p')
    pPr = OxmlElement('w:pPr')
    if style_id:
        ps = OxmlElement('w:pStyle')
        ps.set(qn('w:val'), style_id)
        pPr.append(ps)
    p.append(pPr)
    r = OxmlElement('w:r')
    rPr = OxmlElement('w:rPr')
    r.append(rPr)
    t = OxmlElement('w:t')
    t.set(qn('xml:space'), 'preserve')
    t.text = text
    r.append(t)
    p.append(r)
    return p


def make_table(rows_data, widths=None):
    """rows_data: list of list of str；返回带边框的 tbl 元素"""
    nrows = len(rows_data)
    ncols = len(rows_data[0])
    tbl = OxmlElement('w:tbl')
    tblPr = OxmlElement('w:tblPr')
    tblW = OxmlElement('w:tblW')
    tblW.set(qn('w:w'), '0')
    tblW.set(qn('w:type'), 'auto')
    tblPr.append(tblW)
    borders = OxmlElement('w:tblBorders')
    for edge in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        e = OxmlElement('w:' + edge)
        e.set(qn('w:val'), 'single')
        e.set(qn('w:sz'), '4')
        e.set(qn('w:space'), '0')
        e.set(qn('w:color'), '000000')
        borders.append(e)
    tblPr.append(borders)
    tblLook = OxmlElement('w:tblLook')
    tblLook.set(qn('w:val'), '04A0')
    tblPr.append(tblLook)
    tbl.append(tblPr)
    for r in rows_data:
        tr = OxmlElement('w:tr')
        for c in r:
            tc = OxmlElement('w:tc')
            tcPr = OxmlElement('w:tcPr')
            tcW = OxmlElement('w:tcW')
            tcW.set(qn('w:w'), '0')
            tcW.set(qn('w:type'), 'auto')
            tcPr.append(tcW)
            tc.append(tcPr)
            p = OxmlElement('w:p')
            rr = OxmlElement('w:r')
            tt = OxmlElement('w:t')
            tt.set(qn('xml:space'), 'preserve')
            tt.text = c
            rr.append(tt)
            p.append(rr)
            tc.append(p)
            tr.append(tc)
        tbl.append(tr)
    return tbl


# ---------- 1. 修改封面主标题 ----------
cover = None
for el in body:
    if el.tag == qn('w:p'):
        texts = ''.join(t.text or '' for t in el.iter(qn('w:t')))
        if texts == '生活服务小程序全流程上架方案':
            cover = el
            break
if cover is not None:
    # 保留原 run 结构，只改第一个含文字的 run
    for r in cover.iter(qn('w:r')):
        ts = list(r.findall(qn('w:t')))
        if ts:
            ts[0].text = '生活服务小程序合法合规上架准备'
            for extra in ts[1:]:
                extra.text = ''
            break

# ---------- 2. 删除正文与参考来源（index 75..197 对应区域） ----------
children = list(body)
# 找到'一、项目概述'与'参考来源'第10条之间的所有元素
start_el = None
end_el = None
for el in children:
    if el.tag == qn('w:p'):
        texts = ''.join(t.text or '' for t in el.iter(qn('w:t')))
        if texts.strip() == '一、项目概述':
            start_el = el
        if texts.strip().startswith('10. 小程序备案申请填报指南'):
            end_el = el
if start_el is not None:
    # 从 start_el 开始删除直到 end_el（含）
    cur = start_el
    while cur is not None:
        nxt = cur.getnext()
        if end_el is not None and cur is end_el:
            body.remove(cur)
            break
        body.remove(cur)
        cur = nxt
    print('removed from 一、项目概述 through 参考来源 entries')

# ---------- 3. 追加新内容 ----------
def H1(t):
    body.append(make_para(t, h1_id))

def H2(t):
    body.append(make_para(t, h2_id))

def P(t):
    body.append(make_para(t))

def TB(rows):
    body.append(make_table(rows))

# ===== 一、营业执照注册 =====
H1('一、营业执照注册')
P('小程序以企业主体注册运营，第一步是完成公司（企业）登记并取得营业执照。以下为办理所需的材料与逐步操作。')

H2('1.1 注册前需要确认的事项')
P('① 主体类型：建议注册有限责任公司。企业主体是开通小程序、完成备案与后续结算的基础，个体户在平台型业务和对公结算方面受限较多。')
P('② 公司名称：准备2～3个备选名称，格式为“行政区划＋字号＋行业＋组织形式”，如“天津××生活服务有限公司”；字号避免与已注册企业重复。')
P('③ 注册地址：实际经营地址或园区集群注册地址（需能提供产权证明或租赁合同）。')
P('④ 注册资本：实行认缴制，无需实缴，按业务规模填写（生活服务类一般填写10～100万元即可）。')
P('⑤ 经营范围：对照下方1.4建议文本，与登记机关核对后确定，必须覆盖实际全部业务。')

H2('1.2 需要准备的材料')
TB([
    ['材料', '说明'],
    ['公司名称', '备选2～3个，用于核名'],
    ['股东信息', '各股东身份证照片、出资比例'],
    ['法定代表人信息', '身份证、手机号、电子邮箱'],
    ['注册地址证明', '房产证复印件／租赁合同／园区入驻证明'],
    ['财务负责人与联络员', '身份证与联系方式（用于税务与年报联系）'],
    ['公司章程', '登记系统自动生成或使用模板'],
])

H2('1.3 办理步骤（每步做什么）')
P('第1步 名称预先核准：登录当地市场监管局“企业开办一网通办”平台（或当地政务服务网），提交公司名称查重申请，通过后名称予以保留。')
P('第2步 在线填报设立信息：填写公司登记申请书，内容包括股东出资、法定代表人、注册地址、经营范围等。')
P('第3步 电子签名确认：法定代表人、股东、监事等通过市场监管部门官方实名认证工具完成身份核验与电子签名。')
P('第4步 提交并等待审核：提交设立登记申请，市场监管部门审核，线上全流程一般1～3个工作日（以当地实际为准）。')
P('第5步 领取营业执照：审核通过后领取电子营业执照（即时生成），纸质执照可选择邮寄或到窗口领取。')
P('第6步 领取执照后事项：刻制公章、财务章、法人章（公安备案）；开立银行对公账户；办理税务登记并核定税种。涉及食品销售的，同步办理《食品经营许可证》或仅销售预包装食品备案。')

H2('1.4 经营范围建议（供与登记机关核对）')
P('以下为建议覆盖的表述，供与登记机关核对后写入经营范围；最终以登记机关核定为准。')
P('家政服务；家庭服务；居民日常生活服务；')
P('家用电器维修服务；家具安装和维修服务；开锁服务（涉及开锁业务的需具备公安备案）；')
P('住宅室内装饰装修；建筑装饰装修工程施工；房屋建筑工程施工（自建房相关）；')
P('建筑材料销售；五金产品零售；家用电器销售；')
P('养老服务；老年人养护服务；居家养老服务；助餐、助洁、助浴服务；适老化改造服务；')
P('食品销售（仅销售预包装食品）；食品互联网销售；')
P('互联网信息服务；信息技术咨询服务；家政服务信息中介服务。')
P('注意：如经营现制现售、生鲜等非预包装食品，需同步申请《食品经营许可证》，经营范围相应调整。')

H2('1.5 注意事项')
P('① 营业执照主体必须与后续小程序注册主体、备案主体100%一致。')
P('② 经营范围未覆盖的业务不能开展，提审时若发现经营范围不符会被驳回，需先办理工商变更增项。')
P('③ 执照信息（名称、统一社会信用代码、法定代表人）后续用于小程序注册与备案，务必与证件完全一致。')

# ===== 二、小程序备案 =====
H1('二、小程序备案')
P('根据工信部要求，小程序上线前须完成备案。企业主体在微信公众平台提交，由属地通信管理局审核。')

H2('2.1 备案前需要确认的事项')
P('① 备案主体：与营业执照主体完全一致（企业主体）。')
P('② 小程序账号：先在微信公众平台以企业主体注册小程序账号（注册时需提供营业执照、法人信息）。')
P('③ 小程序负责人：可为企业员工，需提供身份证与手机号（接收审核短信）。')
P('④ 小程序名称：须与单位性质相符并在经营范围内，不使用金融、医药、新闻等需前置审批的关键词。')

H2('2.2 需要准备的材料')
TB([
    ['材料', '说明'],
    ['营业执照', '统一社会信用代码、证照照片/扫描件'],
    ['法定代表人信息', '姓名、身份证号'],
    ['负责人身份证正反面', '小程序负责人的身份证照片'],
    ['负责人手机号', '用于接收备案审核短信'],
    ['真实性承诺书', '备案系统自动生成，核对信息后确认'],
    ['小程序名称', '与经营范围相关的名称'],
])

H2('2.3 办理步骤（每步做什么）')
P('第1步 登录微信公众平台：进入已注册的小程序管理后台。')
P('第2步 进入备案入口：点击“设置—服务内容声明—小程序备案”。')
P('第3步 填写主体信息：核对并完善营业执照信息、法定代表人信息（系统会带出注册信息，逐项核对）。')
P('第4步 填写负责人信息：上传负责人身份证正反面，填写手机号并接收验证短信。')
P('第5步 填写小程序信息：填写名称、服务内容类型；生活服务类一般不涉及前置审批项，按实际选填。')
P('第6步 上传材料并确认：上传营业执照、身份证，确认系统生成的《真实性承诺书》内容无误。')
P('第7步 提交审核：平台先进行初审，通过后转交属地通信管理局审核。')
P('第8步 备案完成：审核通过后获得备案号，并按微信要求在小程序内展示备案号。')

H2('2.4 审核周期与注意事项')
P('① 审核周期：平台初审一般即时或当日完成；管局审核一般为数个工作日（各省不同，以实际为准）。')
P('② 一致性：备案主体必须与营业执照主体、小程序注册主体100%一致，否则无法通过。')
P('③ 备案通过前小程序不能发布上线；备案与开发可并行推进，不影响开发工作。')
P('④ 备案状态可随时在备案页面查询；材料有问题被驳回时，按提示修改后重新提交。')

# ===== 三、上架前材料总清单 =====
H1('三、上架前材料总清单（营业执照＋备案）')
P('按以下清单逐项核对，全部齐备后再进行后续的微信认证、类目申请与提审上架。')
H2('3.1 营业执照注册类')
P('□ 营业执照已领取，经营范围覆盖全部实际业务')
P('□ 公章、财务章、法人章已刻制并完成公安备案')
P('□ 银行对公账户已开立')
P('□ 税务登记已完成')
P('□ 涉及食品销售的：《食品经营许可证》或仅销售预包装食品备案已取得')
H2('3.2 小程序备案类')
P('□ 小程序账号已以企业主体注册')
P('□ 小程序备案已提交')
P('□ 备案审核已通过（获得备案号）')
P('□ 备案号已按微信要求在小程序内展示')

# ===== 参考来源 =====
H1('参考来源')
P('1. 小程序备案操作指引（微信官方）：https://developers.weixin.qq.com/minigame/product/record/record_guidelines.html')
P('2. 微信开放社区：小程序备案流程说明：https://developers.weixin.qq.com/community/develop/doc/0006e22c420b2825c9c37dfc46b000')
P('3. 小程序备案申请填报指南（湖北省通信管理局）：https://hubca.miit.gov.cn/cms_files/filemanager/1620513482/attach/20258/c88c0a8ea898416aaa85e29231d8aa41.pdf')

doc.save(PATH)
print('REBUILD_OK')
