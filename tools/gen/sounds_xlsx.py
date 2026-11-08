# Writes docs/Sweetpotato_Sounds.xlsx and docs/SOUNDS.md (task 2.23): every sound key the game plays,
# where it plays, search words for the Roblox Creator Store, and a yellow ID column the developer fills in.
# Keys must match Config.Sounds / Config.Music. Run with any Python that has openpyxl, for example:
#   python tools/gen/sounds_xlsx.py
import os

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.worksheet.datavalidation import DataValidation

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# (group, key, where it plays, search words, loop)
SOUNDS = [
    ("UI", "click", "Every button (not the fishing HOLD button)", "button click, pop click, ui tap", "no"),
    ("UI", "open", "A window opens (Shop, My Cats, Book, Rewards, Settings...)", "menu open, whoosh pop", "no"),
    ("UI", "error", "Not enough money, zone locked, need Strength, pen full, code wrong", "error, denied, buzz soft", "no"),
    ("UI", "toast", "Small notices", "notification ding, soft ding", "no"),
    ("UI", "claim", "Daily login, playtime gifts, quests, codes, group reward", "reward chime, sparkle, collect", "no"),
    ("UI", "buy", "Shop purchases, weights / treadmill upgrades, Robux purchases", "purchase, cash register, buy", "no"),
    ("UI", "coins", "Selling a cat, money rewards, offline income", "coins, coin collect, money", "no"),
    ("Catching", "cast", "A rod is cast (heard by players nearby)", "fishing cast, whip swoosh, rod cast", "no"),
    ("Catching", "reel", "While your own catching minigame runs", "fishing reel loop, reel clicking", "YES"),
    ("Catching", "catch", "You won the minigame", "success, catch, win short", "no"),
    ("Catching", "escape", "The cat got away", "fail cartoon, boing down, whoosh away", "no"),
    ("Catching", "meow", "Hidden cats nearby meow now and then (a hint); a caught cat", "cat meow, kitten meow", "no"),
    ("Carry and bat", "swing", "A baseball bat swing (heard nearby)", "swing whoosh, bat swing", "no"),
    ("Carry and bat", "bonk", "A bat hit lands (you hit someone / you get hit)", "bonk cartoon, baseball bat hit", "no"),
    ("Carry and bat", "drop", "Your carried cat is knocked loose", "drop, cartoon fall, pop", "no"),
    ("Carry and bat", "deliver", "A cat reaches your pen", "success chime, deliver, ding ding", "no"),
    ("Training and progress", "train", "Each Strength / Speed gain while training (soft, often)", "pop soft, tick, blip", "no"),
    ("Training and progress", "rebirth", "Rebirth done", "magic transform, power up, level up", "no"),
    ("Training and progress", "like", "A like given or received", "like, heart pop, positive blip", "no"),
    ("Training and progress", "fanfare", "A Mythical / Secret cat caught", "fanfare short, victory", "no"),
    ("Crates", "crate_shake", "The crate shakes before it opens", "box shake, rattle", "no"),
    ("Crates", "crate_reveal", "The cat is shown (Basic to Epic)", "reveal, pop, unbox", "no"),
    ("Crates", "crate_rare", "The cat is shown (Legendary or better)", "rare reveal, magic sparkle, jackpot", "no"),
    ("Events", "event_start", "A Mythical / Secret event or server luck starts", "alert horn cartoon, event start", "no"),
]
MUSIC = [
    ("Music", "Lobby", "In the lobby (inside the lobby ring)", "happy music loop, cute, upbeat", "YES"),
    ("Music", "Zones", "Out in the 5 zones", "adventure music loop, cheerful", "YES"),
    ("Music", "Mythical", "While a Mythical event is live", "epic music loop, exciting", "YES"),
    ("Music", "Secret", "While a Secret event is live", "mystery music loop, magical", "YES"),
]

YELLOW = PatternFill("solid", fgColor="FFF2A8")
GREY = PatternFill("solid", fgColor="E6E6E6")
HEAD = PatternFill("solid", fgColor="7E57C2")
THIN = Side(style="thin", color="BBBBBB")
BOX = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)


def build_xlsx(path):
    wb = Workbook()
    ws = wb.active
    ws.title = "Sounds"
    ws["A1"] = "Sweetpotatoturtlenix - sounds and music"
    ws["A1"].font = Font(bold=True, size=14)
    ws["A2"] = ("Pick free Roblox-licensed audio in the Creator Store (Studio -> Toolbox -> Audio), copy its "
                "number into the yellow ID column. Blank = not wanted (silent). Short effects: under 2 s. "
                "Loops: seamless. Send the file back and the ids go into Config.Sounds / Config.Music.")
    ws["A2"].alignment = Alignment(wrap_text=True, vertical="top")
    ws.merge_cells("A2:H2")
    ws.row_dimensions[2].height = 48

    head = ["#", "Group", "Key (do not change)", "Where it plays", "Search words (Creator Store)", "Loop", "ID", "Status"]
    for c, h in enumerate(head, 1):
        cell = ws.cell(row=4, column=c, value=h)
        cell.font = Font(bold=True, color="FFFFFF")
        cell.fill = HEAD
        cell.border = BOX
        cell.alignment = Alignment(vertical="center")

    # grey example row
    example = ["ex", "UI", "click", "Example: every button", "button click", "no", 1234567890, "example"]
    for c, v in enumerate(example, 1):
        cell = ws.cell(row=5, column=c, value=v)
        cell.fill = GREY
        cell.font = Font(italic=True, color="777777")
        cell.border = BOX

    rows = SOUNDS + MUSIC
    first = 6
    for i, (group, key, where, words, loop) in enumerate(rows):
        r = first + i
        values = [i + 1, group, key, where, words, loop, None, None]
        for c, v in enumerate(values, 1):
            cell = ws.cell(row=r, column=c, value=v)
            cell.border = BOX
            cell.alignment = Alignment(wrap_text=True, vertical="top")
        ws.cell(row=r, column=7).fill = YELLOW
        ws.cell(row=r, column=8, value=f'=IF(G{r}="","not picked",IF(ISNUMBER(G{r}),"ok","numbers only"))')
    last = first + len(rows) - 1

    dv = DataValidation(type="whole", operator="greaterThan", formula1="0", allow_blank=True,
                        error="Only the number of the sound (for example 1234567890)", showErrorMessage=True)
    ws.add_data_validation(dv)
    dv.add(f"G{first}:G{last}")

    ws.cell(row=last + 2, column=6, value="Filled").font = Font(bold=True)
    ws.cell(row=last + 2, column=7, value=f'=COUNT(G{first}:G{last})&" / {len(rows)}"').font = Font(bold=True)

    widths = [5, 20, 18, 52, 38, 7, 16, 14]
    for c, w in enumerate(widths, 1):
        ws.column_dimensions[chr(64 + c)].width = w
    ws.freeze_panes = "A5"
    wb.save(path)


def build_md(path):
    out = ["# Sweetpotatoturtlenix - sounds and music (task 2.23)", "",
           "Ids go into `Config.Sounds` / `Config.Music` (`src/shared/Config.luau`); 0 = silent. The developer picks",
           "every id (free Roblox-licensed audio from the Creator Store) in `docs/Sweetpotato_Sounds.xlsx` and sends",
           "it back. Claude never picks ids. Each key plays everywhere its row says; `SoundController` decides when.",
           "Volumes: `Config.SoundVolumes`; music volume / fade: `Config.MusicVolume` / `Config.MusicFade`.",
           "Players switch Music and Sound effects off in Settings (saved).", "",
           "Generated by `tools/gen/sounds_xlsx.py` (keep it in step with Config).", ""]
    group = None
    for g, key, where, words, loop in SOUNDS + MUSIC:
        if g != group:
            group = g
            out += [f"## {g}", "", "| Key | Where it plays | Search words | Loop |", "|---|---|---|---|"]
        out.append(f"| `{key}` | {where} | {words} | {loop} |")
        nxt = (SOUNDS + MUSIC)
        idx = nxt.index((g, key, where, words, loop))
        if idx + 1 == len(nxt) or nxt[idx + 1][0] != g:
            out.append("")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out))


if __name__ == "__main__":
    build_xlsx(os.path.join(ROOT, "docs", "Sweetpotato_Sounds.xlsx"))
    build_md(os.path.join(ROOT, "docs", "SOUNDS.md"))
    print(f"{len(SOUNDS)} sounds + {len(MUSIC)} songs")
