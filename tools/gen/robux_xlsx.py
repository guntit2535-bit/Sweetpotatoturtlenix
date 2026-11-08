# Writes docs/Sweetpotato_Robux.xlsx (in Thai, for the developer): the 5 game passes and 12 developer products
# to create in the group's experience, with the English name / description to paste into Creator Hub, a
# suggested price (the client confirms every price), and yellow columns for the client's price and the id.
# Keys must match Config.Passes / Config.Products.List. Run with any Python that has openpyxl:
#   python tools/gen/robux_xlsx.py
import os

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# (kind, key, name in Roblox, description in Roblox, what it does (Thai), suggested Robux)
ITEMS = [
    ("Game Pass", "Speed2x", "x2 Speed", "Walk twice as fast. Switch it on or off any time with the x2 Speed button.",
     "เดินเร็ว 2 เท่า เปิด/ปิดได้ (ลูกค้ายังไม่ตอบว่าแบบถาวรหรือแบบจับเวลา ตอนนี้ตั้งเป็นถาวร)", 149),
    ("Game Pass", "Cash2x", "x2 Cash", "All your cats earn twice the money, forever.",
     "แมวทุกตัวหาเงินได้ 2 เท่า ถาวร", 299),
    ("Game Pass", "Strength2x", "x2 Strength", "Get twice the Strength from lifting weights, forever.",
     "ยกน้ำหนักได้พลัง 2 เท่า ถาวร", 249),
    ("Game Pass", "Lucky", "Lucky", "x2 luck: more Gold, Rainbow and Glow cats when you catch or open crates.",
     "โชค x2: ได้แมวทอง / สีรุ้ง / เรืองแสง บ่อยขึ้น (ตอนจับแมวและเปิดกล่อง)", 199),
    ("Game Pass", "VIP", "VIP", "A gold VIP tag over your head and 10% more money.",
     "ป้าย VIP สีทองเหนือหัว + เงินเพิ่ม 10%", 149),
    ("Developer Product", "Slots1", "+20 Pen Slots (1)", "Your pen holds 20 more cats.",
     "ช่องคอก +20 ครั้งที่ 1 (ราคาถูกสุด)", 49),
    ("Developer Product", "Slots2", "+20 Pen Slots (2)", "Your pen holds 20 more cats.",
     "ช่องคอก +20 ครั้งที่ 2 (แพงขึ้น)", 99),
    ("Developer Product", "Slots3", "+20 Pen Slots (3)", "Your pen holds 20 more cats (up to 60).",
     "ช่องคอก +20 ครั้งที่ 3 (แพงสุด คอกเต็ม 60 ช่อง)", 199),
    ("Developer Product", "CashS", "Small Cash Pack", "10 minutes of your income now (at least $5K).",
     "ได้เงินเท่ารายได้ 10 นาที (อย่างน้อย 5,000)", 25),
    ("Developer Product", "CashM", "Medium Cash Pack", "1 hour of your income now (at least $25K).",
     "ได้เงินเท่ารายได้ 1 ชั่วโมง (อย่างน้อย 25,000)", 79),
    ("Developer Product", "CashL", "Large Cash Pack", "4 hours of your income now (at least $100K).",
     "ได้เงินเท่ารายได้ 4 ชั่วโมง (อย่างน้อย 100,000)", 199),
    ("Developer Product", "CashXL", "Huge Cash Pack", "12 hours of your income now (at least $400K).",
     "ได้เงินเท่ารายได้ 12 ชั่วโมง (อย่างน้อย 400,000)", 449),
    ("Developer Product", "Strength", "Strength Pack", "1 hour of lifting at your weights level, now (at least 500 kg).",
     "ได้พลังเท่ายกน้ำหนัก 1 ชั่วโมง (อย่างน้อย 500 กก.)", 99),
    ("Developer Product", "Luck3", "Luck x3 (15 min)", "x3 luck for 15 minutes: more Gold, Rainbow and Glow cats.",
     "โชค x3 นาน 15 นาที (ซื้อซ้ำได้ เวลาบวกต่อ)", 49),
    ("Developer Product", "ServerLuck", "Server Luck (15 min)", "Everyone in the server gets x2 luck (more Gold, Rainbow and Glow cats) for 15 minutes, and your name is announced.",
     "ทุกคนในเซิร์ฟเวอร์ได้โชค x2 นาน 15 นาที และประกาศชื่อคนซื้อ", 199),
    ("Developer Product", "SummonMythical", "Summon a Mythical Cat", "A Mythical cat appears now. Everyone can try to catch it!",
     "เรียกแมว Mythical ออกมาทันที ทุกคนแย่งกันจับได้", 149),
    ("Developer Product", "Starter", "Starter Pack", "Iron Rod + $10K + Lucky Treat + Golden Fish. Once per player.",
     "เบ็ดเหล็ก + เงิน 10,000 + ขนมนำโชค + ปลาทองคำ (ซื้อได้คนละครั้ง)", 49),
]

YELLOW = PatternFill("solid", fgColor="FFF2A8")
HEAD = PatternFill("solid", fgColor="7E57C2")
PASS = PatternFill("solid", fgColor="E3F2FD")
THIN = Side(style="thin", color="BBBBBB")
BOX = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)


def build(path):
    wb = Workbook()
    ws = wb.active
    ws.title = "ของขาย Robux"
    ws["A1"] = "Sweetpotatoturtlenix - Game Pass 5 + Developer Product 12"
    ws["A1"].font = Font(bold=True, size=14)
    ws["A2"] = ("สร้างทีละรายการในเว็บ create.roblox.com (เกมของกลุ่ม) คัดลอก \"ชื่อใน Roblox\" และ \"คำอธิบายใน Roblox\" "
                "ไปวาง ใส่ราคา แล้วคัดลอกเลข id มาใส่ช่องสีเหลือง ราคาแนะนำเป็นแค่จุดเริ่ม ลูกค้าเป็นคนยืนยันราคา "
                "(เปลี่ยนราคาในเว็บทีหลังได้ ไม่ต้องแก้เกม) เสร็จแล้วบันทึกไฟล์แล้วบอก Claude")
    ws["A2"].alignment = Alignment(wrap_text=True, vertical="top")
    ws.merge_cells("A2:J2")
    ws.row_dimensions[2].height = 64

    head = ["ลำดับ", "ประเภท", "ชื่อในเกม (ห้ามแก้)", "ชื่อใน Roblox (คัดลอกไปวาง)", "คำอธิบายใน Roblox (คัดลอกไปวาง)",
            "ทำอะไรในเกม", "ราคาแนะนำ (Robux)", "ราคาที่ลูกค้ายืนยัน", "เลข id", "สถานะ"]
    for c, h in enumerate(head, 1):
        cell = ws.cell(row=4, column=c, value=h)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = HEAD
        cell.border = BOX
        cell.alignment = Alignment(vertical="center", wrap_text=True)
    ws.row_dimensions[4].height = 34

    first = 5
    for i, (kind, key, name, desc, th, price) in enumerate(ITEMS):
        r = first + i
        values = [i + 1, kind, key, name, desc, th, price, None, None, None]
        for c, v in enumerate(values, 1):
            cell = ws.cell(row=r, column=c, value=v)
            cell.border = BOX
            cell.alignment = Alignment(wrap_text=True, vertical="top")
            if kind == "Game Pass" and c <= 7:
                cell.fill = PASS
        ws.cell(row=r, column=8).fill = YELLOW
        ws.cell(row=r, column=9).fill = YELLOW
        ws.cell(row=r, column=10, value=f'=IF(I{r}="","ยังไม่สร้าง",IF(ISNUMBER(I{r}),"เรียบร้อย","ใส่ได้แค่ตัวเลข"))')
    last = first + len(ITEMS) - 1
    ws.cell(row=last + 2, column=8, value="สร้างแล้ว").font = Font(bold=True)
    ws.cell(row=last + 2, column=9, value=f'=COUNT(I{first}:I{last})&" / {len(ITEMS)}"').font = Font(bold=True)

    widths = [7, 18, 16, 24, 44, 40, 12, 14, 18, 14]
    for c, w in enumerate(widths, 1):
        ws.column_dimensions[chr(64 + c)].width = w
    ws.freeze_panes = "A5"
    wb.save(path)


if __name__ == "__main__":
    build(os.path.join(ROOT, "docs", "Sweetpotato_Robux.xlsx"))
    print(f"{len(ITEMS)} items")
