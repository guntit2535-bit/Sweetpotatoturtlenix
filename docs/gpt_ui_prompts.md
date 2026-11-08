# ออกแบบ UI ใหม่ด้วย GPT: แนวแมวน่ารัก (งาน R9)

ภาพจาก GPT มี 2 แบบ
- **ภาพหน้าจอ (mockup ข้อ 0-12):** ใช้กำหนดหน้าตาเท่านั้น ผมสร้าง UI จริงใน Roblox ตามภาพ (ปุ่มกดได้ ตัวเลขเปลี่ยนจริง
  สลับ EN/TH ได้ ปรับตามจอมือถือ/PC) ตัวหนังสือในภาพจึงเป็นภาษาอังกฤษ เพราะ GPT เขียนภาษาไทยเพี้ยน
- **ภาพชิ้นส่วน (ไอคอน P01-P12):** ไอคอนที่ใช้จริงในเกม (ปุ่มเมนู เหรียญ พลัง ความเร็ว) ผมลบพื้นและย่อขนาดให้
  เหมือนรูปของขาย แล้วคุณอัปโหลดเข้ากลุ่ม

## ลำดับที่แนะนำ
1. เปิดแชทใหม่ แนบรูป `art/preview/cats_lineup.jpg` (แมวจริงในเกม) แล้วพิมพ์ก่อน:
   `This is my own game's art. Use exactly this smooth blocky cat style (no studs) for every cat in the next images.`
2. ทำ **ข้อ 0 (Style board)** ก่อน ถ้ายังไม่ถูกใจ ให้แก้หรือสั่งทำใหม่จนพอใจ แล้วส่งให้ผมดูด้วย
3. ใช้ **แชทเดิม** ทำข้อ 1-12 ทีละข้อ (ทุกข้อบอกให้ใช้สไตล์ของ style board ในแชทนี้)
4. ไอคอน P01-P12 ทำในแชทเดิมต่อได้เลย
5. ตั้งชื่อไฟล์ตามรหัสในหัวข้อ (เช่น `00_style_board.png`, `P01_shop.png`) ใส่ที่ `art/source/gpt_ui/` แล้วบอกผม

## กติกา (เขียนไว้ในทุก prompt แล้ว)
- หน้าจอ: **1536 x 1024 แนวนอน** · ไอคอน: **1024 x 1024 พื้นหลังโปร่งใส** (ได้พื้นขาวก็ส่งมาได้ ผมลบให้)
- เว้นมุมซ้ายบนว่าง (ปุ่มของ Roblox อยู่ตรงนั้น) และมุมขวาล่าง (ปุ่มกระโดดบนมือถือ)
- ไม่เอ่ยชื่อเกมอื่น Lego หรือ Roblox ไม่มีโลโก้
- ฟอนต์: ให้ GPT ใช้ฟอนต์การ์ตูนหนาโค้งมน ผมจะเลือกฟอนต์ใน Roblox ที่ใกล้ที่สุด

## เคล็ดลับ (พิมพ์ต่อในแชทเดิมเมื่อภาพเพี้ยน)
- ไม่ตรงสไตล์ข้อ 0: `Use exactly the same UI style, colours, font and panel shapes as the style board above.`
- ตัวหนังสือเพี้ยน: `Fix the text: write exactly "<ข้อความ>", nothing else.`
- รกเกินไป: `Simpler: fewer decorations, more empty space, bigger buttons and text.`
- อยากลองสีอื่นตอนทำข้อ 0 ให้แก้ประโยคสีในกล่อง เช่น
  - ฟ้าพาสเทล: `panels in soft baby blue (#BFE6FF) with a dark navy outline`
  - มิ้นต์: `panels in soft mint (#C9F5DF) with a dark navy outline`

---

## 0. `00_style_board` — Style board (ชิ้น UI ทุกแบบในภาพเดียว)
```
A UI kit style sheet for a mobile game, laid out neatly on a plain soft light background (#FFF6EC), like a designer's
component board. The game is a cheerful kids' cat-catching game; its world is made of smooth glossy blocky shapes and
cute blocky cats (cube heads, triangle ears with pink insides, small square eyes, pink blush).
UI style "cute cat": soft rounded panels in warm cream (#FFF3DA) with a thick dark navy outline (#2A2F4F) and a soft
peach inner border; every window has two small rounded cat ears with pink insides on its top edge and a faint paw-print
pattern inside. Buttons are fat, glossy, rounded "jelly" buttons in candy pastel colours with a darker 3D lip under them
and a tiny white paw print in one corner. Close buttons are round and pink with a white "X". All text is a very chunky,
rounded, bold cartoon display font (similar to Fredoka One), white with a thick dark navy outline and a small drop shadow
(dark navy text on light panels). Small decorations: paw prints, tiny fish, yarn balls, whisker lines. Bright, soft,
friendly and very easy to read on a phone.
Show these components, each with a small grey caption under it:
1. A large window panel with a pink title banner shaped like a cat head on top saying "SHOP" (two ears on the banner)
   and a round pink close button with a white "X" at the top-right. Caption "Window".
2. A row of 6 buttons, one per colour, each saying "BUY": yellow #FFD23F, green #4CD98A, blue #5EC4FF, orange #FF9A5C,
   purple #B48CFF, pink #FF7FB6; plus one grey #A3A8B8 disabled button and one green button shown pressed down (lip
   sunk). Caption "Buttons".
3. A tab bar with 4 tabs "RODS", "SHOES", "CRATES", "ROBUX", the first one selected (yellow, raised, with tiny ears),
   the others cream. Caption "Tabs".
4. An on/off toggle switch shaped like a paw: one ON (green) and one OFF (grey). Caption "Switch".
5. Two progress bars with thick outlines and rounded ends: one green 60% full labelled "6/10" with a tiny cat head
   riding the end of the fill; one pink 30% full. Caption "Bars".
6. A pill-shaped counter with a shiny gold coin (a paw print stamped on it) and "1.2Sx" and a small green "+161/s";
   under it a second pill with a red dumbbell icon and "8.5Qa kg". Caption "Stats".
7. Two square menu buttons (rounded, chunky, with lip, cat ears on top): a pink one with a white shopping bag icon and
   a yellow one with a white gift box icon, each with a short label under the icon. Caption "Menu buttons".
8. A small item card: cream card with a picture area (a cute blocky orange tabby cat), the title "GINGER MOCHI", a
   small purple tier ribbon "EPIC", and a green price button "$2.5M". Caption "Card".
9. A small toast notification bar: green rounded strip with a paw icon saying "+1,200!". Caption "Toast".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names, no other games' UI.
```

---

## 1. `01_hud` — หน้าจอหลักขณะเล่น (HUD)
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape) of a cheerful kids' cat-catching game, showing the main HUD over the game world: a
bright lobby of green checkered grass in two shades of green, wooden cat pens with cute blocky cats, a blue sky. A
blocky toy-figure kid player stands in the middle holding a fishing rod.
HUD, all in the cute cat style:
- Left side, a column of 4 big square menu buttons with cat ears on top, each with a white icon and a short label:
  pink "Shop" (shopping bag), blue "x2 Speed" (winged sneaker, with a small "ON" badge), yellow "My Cats" (cat face),
  purple "Trade" (two paws swapping).
- Top right: a round purple settings button (a gear with two cat ears) labelled "Settings". Under it a cream panel
  with a red dumbbell icon, "Strength" and a big "8.5Qa kg", and two small lines "Weights Lv 12/25" and "Treadmill
  Lv 9/25". Under that, two buttons "Rebirth" (purple) and "Rewards" (green, with a small red "!" badge).
- Bottom left (a little above the corner): a small pill "Speed 4.2T" with a lightning paw icon, and under it a bigger
  money pill with a gold paw coin, "$1.2Sx" and a small green "+3.4Qi/s".
- Bottom centre: a small hotbar with 2 slots: a baseball bat and a fishing rod.
- Bottom right is empty (the phone's jump button is there). Above it, a small dark pill "Mythical in 12:53" with a
  tiny winged cat icon.
- Top left corner empty.
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 2. `02_shop` — ร้านค้า (เงินในเกม)
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): the game world dimmed behind a big centred window titled "SHOP" (cat-head title
banner, pink close button). Under the title a tab bar: "Rods" (selected), "Shoes", "Pen", "Treats", "Crates",
"Robux". The body is a scrolling list of wide cream item rows; each row has a picture on the left, a name, a short
line, and a button on the right:
1. a wooden fishing rod, "Wood Rod 3", "Green zone +12%", grey button "Owned";
2. an iron fishing rod, "Iron Rod 1", "Green zone +20%", green button "$25K";
3. a gold fishing rod, "Gold Rod 1", "Green zone +35%", grey disabled button "$4.5B" with a small lock;
4. a crystal fishing rod, "Crystal Rod 1", "Green zone +50%", grey disabled button "$900T" with a lock.
A money pill at the top-right of the window shows a gold paw coin and "$1.2M".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 3. `03_robux` — แท็บ Robux ในร้านค้า
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): the same "SHOP" window with the "Robux" tab selected. A list of rows, each with a
round glossy item picture on the left, a name, a short line and a green price button on the right:
1. winged blue sneakers with "x2", "x2 Speed", "Walk twice as fast", button "R$ 149";
2. cash and paw coins with "x2", "x2 Cash", "Your cats earn x2 money", button "R$ 299";
3. a red dumbbell with "x2", "x2 Strength", "x2 Strength from lifting", button "R$ 249";
4. a green four-leaf clover with tiny gold / rainbow / glowing cats, "Lucky", "More Gold, Rainbow and Glow cats",
   button "R$ 199";
5. gold letters "VIP" with a crown, "VIP", "VIP tag + 10% more money", a purple button "Owned".
Above the list, a wide pink banner card with a gift box full of coins and a fishing rod: "STARTER PACK" and a yellow
button "R$ 49".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 4. `04_my_cats` — แมวของฉัน
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): a big window titled "MY CATS" with a counter "18 / 30" next to the title and a
small button "Book" with a book icon at the top. The body is a grid of 8 cat cards (2 rows of 4). Each card: a cute
blocky cat picture (different colours: ginger tabby, white, black with white socks, grey, calico, a gold shiny one with
a small "GOLD" ribbon, a rainbow one with a "RAINBOW" ribbon, a lavender one with small wings), a tier ribbon in its
colour (Basic grey, Rare blue, Epic purple, Legendary orange, Mythical pink), the weight "4.2Qa kg", the money "+12T/s",
and a small padlock toggle in the corner (2 cards locked). At the bottom of the window: a red button "Sell" and a
text "Tap a cat to see it".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 5. `05_book` — สมุดสะสม
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): a big window that looks like an open storybook with cat-ear corners, titled
"COLLECTION BOOK", with a counter "137 / 400" and a progress bar with a cat head riding the fill. Tabs along the top:
"Basic", "Rare" (selected), "Epic", "Legendary", "Mythical", "Secret". The pages show a grid of 15 small cat slots:
10 show cute blocky cats in colour with their names under them ("Socks Dumpling", "Calico Sprinkle"...), 5 are solid
dark navy silhouettes of cats with "???" under them. At the bottom a gold ribbon: "Complete Rare: +5% money".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 6. `06_rewards` — รางวัล (ล็อกอินรายวัน ของขวัญ ภารกิจ โค้ด กลุ่ม)
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): a big window titled "REWARDS" with tabs "Daily" (selected), "Gifts", "Quests",
"Codes", "Group". The body shows a row of 7 day cards like a calendar, each with a cute picture and a label: "Day 1"
paw coin "$500", "Day 2" coins "$1.5K", "Day 3" a lucky treat (green fish with a clover), "Day 4" coins "$10K", "Day 5"
a wooden crate, "Day 6" a golden fish, "Day 7" a big gold crate with a glowing cat inside (this card bigger, sparkling).
Days 1-3 have a green check mark, day 4 is glowing with a green button "Claim", days 5-7 are greyed. A small line
under the row: "Come back tomorrow for Day 5!".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 7. `07_rebirth` — รีเบิร์ธ
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): a centred window titled "REBIRTH" with a big magical cat in the middle (a cute
blocky cat glowing purple, rising from a swirl of stars). On the left a card "YOU KEEP": icons of cats, a fishing rod
and shoes. On the right a card "YOU RESET": icons of a coin, a dumbbell and a lightning paw. Under the cat: "Rebirth 3
-> 4" and two green chips "Money x1.5" and "Strength x1.5", a progress bar "Strength 3.2Qa / 5Qa kg" (64% full), and a
big purple button "REBIRTH" (shown disabled until the bar is full).
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 8. `08_trade` — แลกแมว
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): a wide window titled "TRADE" split into two halves with a paw-shaped divider in the
middle. Left half "YOU" with 3 cute blocky cat cards in a grid of 6 slots; right half "PLAYER2" with 2 cat cards in its
6 slots. Under each half a status: left a green "READY" check, right a grey "Not ready". In the middle at the bottom a
big countdown "5" in a circle, a green button "Ready" and a red button "Cancel". Under the window, a strip of your
other cats to tap and add.
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 9. `09_settings` — ตั้งค่า
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape): a centred window titled "SETTINGS" with 3 rows, each a cream panel: "Language"
with two buttons "English" (yellow, selected) and "Thai" (grey); "Music" with a paw toggle switch ON (green); "Sound
effects" with a paw toggle switch ON (green). Small grey notes under each title: "Every text in the game",
"Background music", "Buttons, catching, bats, crates". A tiny sleeping cat curled on the top edge of the window.
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 10. `10_fishing` — มินิเกมตกแมว
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape) during the catching minigame: in the game world a blocky kid holds a fishing rod
whose line reaches a cute blocky cat struggling in a bush. On the right side of the screen a tall vertical bar panel
with a thick outline: inside it a green zone box near the middle and a small cat head icon inside the zone; next to
it a thinner vertical meter, yellow, 70% full. Above the bar a small pink button "Give up". At the bottom right, a big
round green button "HOLD" with a paw print (above the jump button area). At the top centre a hint in big outlined text:
"Hold to keep the cat in the green zone!".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 11. `11_popups` — ป๊อปอัปต่างๆ (4 อันในภาพเดียว)
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game UI sheet (landscape) on a plain soft background showing 4 popups side by side:
1. A "CAUGHT!" card: a cute blocky calico cat in the middle with sparkles, "Calico Sprinkle", a blue "RARE" ribbon,
   "42.5T kg" and "+1.2M/s".
2. A big event banner across the top: "A MYTHICAL CAT APPEARED!" in pink outlined letters with a winged lavender cat
   and stars.
3. Three toasts stacked: green "+$1,200!" with a coin, red "Not enough money" with a sad cat face, blue "Server Luck
   x2 by PLAYER2!" with a clover.
4. A "WELCOME BACK" window: a sleeping cat on a pillow, "Your cats made $3.4Qa while you were away", a green button
   "Collect".
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

## 12. `12_crate_open` — หน้าเปิดกล่องสุ่ม (ภาพสุดท้ายตอนเฉลย)
```
Use exactly the same UI style, colours, font and panel shapes as the style board above.
A mobile game screen (landscape), the moment a crate is opened: in the centre a shiny GOLD crate with its lid flying
off, golden light rays and confetti bursting out, and a cute blocky orange cat with a tiny crown jumping out of it with
a happy face. Under it a card: "Sunny Crown", an orange "LEGENDARY" ribbon, "8.1Qa kg", "+2.4T/s". A small hint at the
bottom: "Tap to continue". Around the screen edges a soft gold glow.
Landscape 1536x1024. English text only, exactly as written. No logos, no brand names.
```

---

# ไอคอน (ใช้บนปุ่มเมนูและป้ายตัวเลข) — 1024 x 1024 พื้นใส

ทุกข้อใช้ประโยคสไตล์เดียวกัน ทำในแชทเดิมต่อจากข้อ 12 ได้เลย

## P01 `P01_shop` — ปุ่ม Shop
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): a cute pink shopping bag with two cat
ears on top and a white paw print on the front, a gold paw coin peeking out. Thin dark navy outline around the whole
shape, simple bold silhouette clear at 64 px, soft studio light from the upper left. Centred, filling about 80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P02 `P02_speed` — ปุ่ม x2 Speed
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): one chunky sky-blue sneaker with a white
wing on the heel and three white speed lines behind it. Thin dark navy outline around the whole shape, simple bold
silhouette clear at 64 px, soft studio light from the upper left. Centred, filling about 80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P03 `P03_my_cats` — ปุ่ม My Cats
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): the face of a cute blocky orange tabby
cat (cube head, triangle ears with pink insides, small square eyes with shine, pink blush, happy smile) peeking over a
small wooden fence. Thin dark navy outline around the whole shape, simple bold silhouette clear at 64 px, soft studio
light from the upper left. Centred, filling about 80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P04 `P04_trade` — ปุ่ม Trade
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): two cute cat paws (one orange, one grey)
passing a small blocky cat toy between them, with two curved arrows (green and blue) circling around. Thin dark navy
outline around the whole shape, simple bold silhouette clear at 64 px, soft studio light from the upper left. Centred,
filling about 80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P05 `P05_settings` — ปุ่ม Settings
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): a chunky white gear with two small cat
ears with pink insides on top and a paw print in its centre hole. Thin dark navy outline around the whole shape, simple
bold silhouette clear at 64 px, soft studio light from the upper left. Centred, filling about 80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P06 `P06_rebirth` — ปุ่ม Rebirth
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): a cute blocky lavender cat sitting
inside a glowing purple circular arrow (a loop), little stars around. Thin dark navy outline around the whole shape,
simple bold silhouette clear at 64 px, soft studio light from the upper left. Centred, filling about 80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P07 `P07_rewards` — ปุ่ม Rewards
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): a chunky green gift box with a yellow
ribbon bow and two cat ears on the lid, a white paw print on the front, a few sparkles. Thin dark navy outline around
the whole shape, simple bold silhouette clear at 64 px, soft studio light from the upper left. Centred, filling about
80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P08 `P08_book` — ปุ่ม Book
```
3D icon for a cheerful kids' cat game, smooth glossy blocky shapes (no studs): a thick closed storybook with a pink
cover, two cat ears on the top edge, a gold paw print on the cover and a bookmark ribbon. Thin dark navy outline around
the whole shape, simple bold silhouette clear at 64 px, soft studio light from the upper left. Centred, filling about
80%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P09 `P09_coin` — เหรียญเงิน
```
3D icon for a cheerful kids' cat game, smooth glossy shapes (no studs): one shiny gold coin seen at a slight angle with
a raised orange paw print on its face and a small sparkle. Thin dark navy outline around the whole shape, simple bold
silhouette clear at 32 px, soft studio light from the upper left. Centred, filling about 85%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it, no currency symbols.
```

## P10 `P10_strength` — ไอคอนพลัง
```
3D icon for a cheerful kids' cat game, smooth glossy shapes (no studs): one chunky red dumbbell with white paw prints
on the weight plates, lying at a slight angle. Thin dark navy outline around the whole shape, simple bold silhouette
clear at 32 px, soft studio light from the upper left. Centred, filling about 85%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P11 `P11_speed_stat` — ไอคอนความเร็ว
```
3D icon for a cheerful kids' cat game, smooth glossy shapes (no studs): a bright yellow lightning bolt with a small
cat paw print on it and two short speed lines. Thin dark navy outline around the whole shape, simple bold silhouette
clear at 32 px, soft studio light from the upper left. Centred, filling about 85%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```

## P12 `P12_event` — ไอคอนอีเวนต์
```
3D icon for a cheerful kids' cat game, smooth glossy shapes (no studs): a small cute lavender cat head with a gold
halo and tiny white wings, next to a small round alarm clock. Thin dark navy outline around the whole shape, simple
bold silhouette clear at 32 px, soft studio light from the upper left. Centred, filling about 85%.
Square 1024x1024, fully transparent background. No text, no logo, no frame, no circle behind it.
```
