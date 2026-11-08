# Writes docs/Sweetpotato_Sounds.xlsx (in Thai, for the developer) and docs/SOUNDS.md (English) (task 2.23):
# every sound key the game plays, where it plays, search words for the Roblox Creator Store (English, the
# store is searched in English), and a yellow ID column the developer fills in.
# Keys must match Config.Sounds / Config.Music. Run with any Python that has openpyxl, for example:
#   python tools/gen/sounds_xlsx.py
import os

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.worksheet.datavalidation import DataValidation

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

GROUPS_TH = {
    "UI": "ปุ่มและหน้าต่าง",
    "Catching": "ตกแมว",
    "Carry and bat": "แบกแมวและไม้เบสบอล",
    "Training and progress": "ฝึกและความก้าวหน้า",
    "Crates": "กล่องสุ่ม",
    "Events": "อีเวนต์",
    "Music": "เพลง",
}

# (group, key, where it plays EN, where it plays TH, search words, loop)
SOUNDS = [
    ("UI", "click", "Every button (not the fishing HOLD button)",
     "กดปุ่มทุกปุ่ม (ยกเว้นปุ่ม HOLD ตอนตกแมว)", "button click, pop click, ui tap", False),
    ("UI", "open", "A window opens (Shop, My Cats, Book, Rewards, Settings...)",
     "เปิดหน้าต่าง (ร้านค้า, แมวของฉัน, สมุดสะสม, รางวัล, ตั้งค่า)", "menu open, whoosh pop", False),
    ("UI", "error", "Not enough money, zone locked, need Strength, pen full, code wrong",
     "เงินไม่พอ, โซนยังล็อก, พลังไม่พอ, คอกเต็ม, โค้ดผิด", "error, denied, buzz soft", False),
    ("UI", "toast", "Small notices",
     "ข้อความแจ้งเตือนเล็กๆ", "notification ding, soft ding", False),
    ("UI", "claim", "Daily login, playtime gifts, quests, codes, group reward",
     "รับรางวัล: ล็อกอินรายวัน, ของขวัญตามเวลาเล่น, ภารกิจ, โค้ด, รางวัลกลุ่ม", "reward chime, sparkle, collect", False),
    ("UI", "buy", "Shop purchases, weights / treadmill upgrades, Robux purchases",
     "ซื้อของในร้าน, อัปเกรดที่ยกน้ำหนัก / ลู่วิ่ง, ซื้อด้วย Robux", "purchase, cash register, buy", False),
    ("UI", "coins", "Selling a cat, money rewards, offline income",
     "ขายแมว, ได้เงินรางวัล, เงินตอนออฟไลน์", "coins, coin collect, money", False),
    ("Catching", "cast", "A rod is cast (heard by players nearby)",
     "เหวี่ยงเบ็ด (คนที่อยู่ใกล้ได้ยินด้วย)", "fishing cast, whip swoosh, rod cast", False),
    ("Catching", "reel", "While your own catching minigame runs",
     "เสียงหมุนรอกตอนเล่นมินิเกมตกแมว (เล่นวนซ้ำ)", "fishing reel loop, reel clicking", True),
    ("Catching", "catch", "You won the minigame",
     "จับแมวได้", "success, catch, win short", False),
    ("Catching", "escape", "The cat got away",
     "แมวหลุดหนีไป", "fail cartoon, boing down, whoosh away", False),
    ("Catching", "meow", "Hidden cats nearby meow now and then (a hint); a caught cat",
     "แมวร้องเหมียว: แมวที่ซ่อนอยู่ใกล้ๆ ร้องเป็นระยะ (เป็นใบ้) และตอนจับได้", "cat meow, kitten meow", False),
    ("Carry and bat", "swing", "A baseball bat swing (heard nearby)",
     "เหวี่ยงไม้เบสบอล (คนที่อยู่ใกล้ได้ยินด้วย)", "swing whoosh, bat swing", False),
    ("Carry and bat", "bonk", "A bat hit lands (you hit someone / you get hit)",
     "ไม้เบสบอลตีโดน (เราตีโดนคนอื่น / เราโดนตี)", "bonk cartoon, baseball bat hit", False),
    ("Carry and bat", "drop", "Your carried cat is knocked loose",
     "แมวที่แบกอยู่หลุดจากมือ", "drop, cartoon fall, pop", False),
    ("Carry and bat", "deliver", "A cat reaches your pen",
     "พาแมวเข้าคอกสำเร็จ", "success chime, deliver, ding ding", False),
    ("Training and progress", "train", "Each Strength / Speed gain while training (soft, often)",
     "ทุกครั้งที่พลัง / ความเร็วเพิ่มตอนฝึก (ดังบ่อย ควรเป็นเสียงเบาๆ)", "pop soft, tick, blip", False),
    ("Training and progress", "rebirth", "Rebirth done",
     "รีเบิร์ธสำเร็จ", "magic transform, power up, level up", False),
    ("Training and progress", "like", "A like given or received",
     "กดไลก์ หรือได้รับไลก์", "like, heart pop, positive blip", False),
    ("Training and progress", "fanfare", "A Mythical / Secret cat caught",
     "จับแมว Mythical / Secret ได้", "fanfare short, victory", False),
    ("Crates", "crate_shake", "The crate shakes before it opens",
     "กล่องสั่นก่อนเปิด", "box shake, rattle", False),
    ("Crates", "crate_reveal", "The cat is shown (Basic to Epic)",
     "เปิดกล่องได้แมวธรรมดา (Basic ถึง Epic)", "reveal, pop, unbox", False),
    ("Crates", "crate_rare", "The cat is shown (Legendary or better)",
     "เปิดกล่องได้แมวหายาก (Legendary ขึ้นไป)", "rare reveal, magic sparkle, jackpot", False),
    ("Events", "event_start", "A Mythical / Secret event or server luck starts",
     "อีเวนต์แมว Mythical / Secret เริ่ม หรือมีคนเปิดโชคทั้งเซิร์ฟเวอร์", "alert horn cartoon, event start", False),
]
MUSIC = [
    ("Music", "Lobby", "In the lobby (inside the lobby ring)",
     "เพลงในล็อบบี้", "happy music loop, cute, upbeat", True),
    ("Music", "Zones", "Out in the 5 zones",
     "เพลงตอนออกไปในโซนทั้ง 5", "adventure music loop, cheerful", True),
    ("Music", "Mythical", "While a Mythical event is live",
     "เพลงตอนแมว Mythical โผล่", "epic music loop, exciting", True),
    ("Music", "Secret", "While a Secret event is live",
     "เพลงตอนแมว Secret โผล่", "mystery music loop, magical", True),
]

YELLOW = PatternFill("solid", fgColor="FFF2A8")
GREY = PatternFill("solid", fgColor="E6E6E6")
HEAD = PatternFill("solid", fgColor="7E57C2")
THIN = Side(style="thin", color="BBBBBB")
BOX = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)


def build_xlsx(path):
    wb = Workbook()
    ws = wb.active
    ws.title = "เสียง"
    ws["A1"] = "Sweetpotatoturtlenix - รายการเสียงและเพลง"
    ws["A1"].font = Font(bold=True, size=14)
    ws["A2"] = ("วิธีกรอก: เปิด Roblox Studio -> Toolbox -> Audio หาเสียงฟรีด้วยคำในช่อง \"คำค้นหา\" "
                "แล้วคัดลอกเลขของเสียงมาใส่ช่องสีเหลือง \"เลขเสียง\" ช่องไหนไม่อยากมีเสียงให้เว้นว่าง "
                "เสียงสั้นควรยาวไม่เกิน 2 วินาที เสียงที่เล่นวนซ้ำควรต่อกันเนียน กรอกเสร็จแล้วส่งไฟล์กลับให้ Claude")
    ws["A2"].alignment = Alignment(wrap_text=True, vertical="top")
    ws.merge_cells("A2:H2")
    ws.row_dimensions[2].height = 64

    head = ["ลำดับ", "หมวด", "ชื่อในเกม (ห้ามแก้)", "เล่นตอนไหน", "คำค้นหา (พิมพ์ภาษาอังกฤษใน Toolbox)",
            "เล่นวนซ้ำ", "เลขเสียง", "สถานะ"]
    for c, h in enumerate(head, 1):
        cell = ws.cell(row=4, column=c, value=h)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = HEAD
        cell.border = BOX
        cell.alignment = Alignment(vertical="center", wrap_text=True)

    # grey example row
    example = ["ตัวอย่าง", "ปุ่มและหน้าต่าง", "click", "ตัวอย่าง: กดปุ่มทุกปุ่ม", "button click", "ไม่", 1234567890, "ตัวอย่าง"]
    for c, v in enumerate(example, 1):
        cell = ws.cell(row=5, column=c, value=v)
        cell.fill = GREY
        cell.font = Font(italic=True, color="777777")
        cell.border = BOX

    rows = SOUNDS + MUSIC
    first = 6
    for i, (group, key, _where_en, where_th, words, loop) in enumerate(rows):
        r = first + i
        values = [i + 1, GROUPS_TH[group], key, where_th, words, "ใช่" if loop else "ไม่", None, None]
        for c, v in enumerate(values, 1):
            cell = ws.cell(row=r, column=c, value=v)
            cell.border = BOX
            cell.alignment = Alignment(wrap_text=True, vertical="top")
        ws.cell(row=r, column=7).fill = YELLOW
        ws.cell(row=r, column=8, value=f'=IF(G{r}="","ยังไม่เลือก",IF(ISNUMBER(G{r}),"เรียบร้อย","ใส่ได้แค่ตัวเลข"))')
    last = first + len(rows) - 1

    dv = DataValidation(type="whole", operator="greaterThan", formula1="0", allow_blank=True,
                        error="ใส่ได้แค่เลขของเสียง เช่น 1234567890", showErrorMessage=True)
    ws.add_data_validation(dv)
    dv.add(f"G{first}:G{last}")

    ws.cell(row=last + 2, column=6, value="กรอกแล้ว").font = Font(bold=True)
    ws.cell(row=last + 2, column=7, value=f'=COUNT(G{first}:G{last})&" / {len(rows)}"').font = Font(bold=True)

    widths = [8, 18, 16, 50, 36, 10, 16, 14]
    for c, w in enumerate(widths, 1):
        ws.column_dimensions[chr(64 + c)].width = w
    ws.freeze_panes = "A5"
    wb.save(path)


def build_md(path):
    out = ["# Sweetpotatoturtlenix - sounds and music (task 2.23)", "",
           "Ids go into `Config.Sounds` / `Config.Music` (`src/shared/Config.luau`); 0 = silent. The developer picks",
           "every id (free Roblox-licensed audio from the Creator Store) in `docs/Sweetpotato_Sounds.xlsx` (in Thai)",
           "and sends it back. Claude never picks ids. Each key plays everywhere its row says; `SoundController`",
           "decides when. Volumes: `Config.SoundVolumes`; music volume / fade: `Config.MusicVolume` / `Config.MusicFade`.",
           "Players switch Music and Sound effects off in Settings (saved).", "",
           "Generated by `tools/gen/sounds_xlsx.py` (keep it in step with Config).", ""]
    rows = SOUNDS + MUSIC
    for i, (g, key, where, _th, words, loop) in enumerate(rows):
        if i == 0 or rows[i - 1][0] != g:
            out += [f"## {g}", "", "| Key | Where it plays | Search words | Loop |", "|---|---|---|---|"]
        out.append(f"| `{key}` | {where} | {words} | {'YES' if loop else 'no'} |")
        if i + 1 == len(rows) or rows[i + 1][0] != g:
            out.append("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    build_xlsx(os.path.join(ROOT, "docs", "Sweetpotato_Sounds.xlsx"))
    build_md(os.path.join(ROOT, "docs", "SOUNDS.md"))
    print(f"{len(SOUNDS)} sounds + {len(MUSIC)} songs")
