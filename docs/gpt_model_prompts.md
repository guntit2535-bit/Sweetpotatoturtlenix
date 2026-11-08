# รูปต้นแบบสำหรับปั้นโมเดลไอเทมใน Blender (งาน R5) — 20 รูป

รูปชุดนี้ **ไม่ได้ใส่ในเกมตรงๆ** ผมใช้เป็นแบบเพื่อปั้นโมเดล 3D ใน Blender ให้หน้าตาเหมือนรูป แล้วส่งภาพเรนเดอร์ให้คุณตรวจก่อน
ผ่านแล้วค่อยเอาเข้า Studio ดังนั้นรูปต้องเห็นรูปทรงชัด มุม 3/4 พื้นหลังเรียบ ไม่ต้องสวยแบบรูปขายของ

## วิธีใช้
1. เปิดแชทใหม่ใน ChatGPT แนบรูป `art/preview/cats_lineup.jpg` แล้วพิมพ์ก่อน:
   `This is my own game's art. Draw every item in the same smooth blocky toy style (no studs) as these cats.`
2. วาง prompt ทีละข้อในแชทเดิม เริ่มจากข้อ M01 (เบ็ดไม้), M11 (ดัมเบลล์ชุดแรก) และ M16 (ลู่วิ่งชุดแรก)
   ส่งให้ผมดูก่อน 3 รูปนี้ ถ้าแนวถูก ทำข้อที่เหลือต่อ
3. ตั้งชื่อไฟล์ตามรหัส (เช่น `M01_rods_wood.png`) ใส่ที่ `art/source/gpt_models/` แล้วบอกผม

## กติกา (เขียนไว้ในทุก prompt แล้ว)
- 1536 x 1024 แนวนอน พื้นหลังสีเทาอ่อนเรียบ ไม่มีพื้นฉาก มุมกล้อง 3/4 จากด้านบนเล็กน้อย
- ของหลายชิ้นในรูปเดียววางเรียงจากซ้ายไปขวา ไม่ทับกัน
- ไม่มีตัวหนังสือ (ยกเว้นตัวเลขที่ระบุ) ไม่มีโลโก้ ไม่มีปุ่มกลม (studs)

## เคล็ดลับ
- ของซ้อนทับกัน: `Same items, spread out in one row with space between them, nothing overlapping.`
- มีปุ่มกลมโผล่มา: `Remove every round stud: all surfaces are smooth and flat.`
- แต่ละขั้นดูไม่ต่างกันพอ: `Make each step clearly bigger and fancier than the one before it.`

---

# เบ็ดตกปลา 25 ขั้น (5 วัสดุ x 5 ขั้น)

## M01 `M01_rods_wood` — เบ็ดไม้ ขั้น 1-5
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five fishing rods lying side by side from left to right, tier 1 to tier 5 of the WOOD set,
each one a little longer and fancier than the one before: warm brown wooden pole with darker wood rings, a chunky reel
on the handle, a red-and-white float and a small hook on the line; tier 1 is plain, tier 3 has green leaf wraps on the
grip, tier 5 has a small carved cat head at the handle end and a green ribbon. All rods the same angle, clearly
separated. Even soft studio lighting, 3/4 view from slightly above.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M02 `M02_rods_iron` — เบ็ดเหล็ก ขั้น 1-5
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five fishing rods side by side, tier 1 to tier 5 of the IRON set, each a little longer and
fancier: grey steel pole with blue grip bands, a chunky metal reel, a red-and-white float; higher tiers add more blue
trim, bolts and a small paw-print badge on the reel; tier 5 has a blue glowing line. Same angle, clearly separated.
Even soft studio lighting, 3/4 view from slightly above.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M03 `M03_rods_gold` — เบ็ดทอง ขั้น 1-5
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five fishing rods side by side, tier 1 to tier 5 of the GOLD set, each a little longer and
fancier: shiny gold pole with red grip, a gold reel, a gold float; higher tiers add red gems, small cat-ear shapes on the
reel and sparkles; tier 5 has a gold cat-head tip and a glowing yellow line. Same angle, clearly separated. Even soft
studio lighting, 3/4 view from slightly above.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M04 `M04_rods_crystal` — เบ็ดคริสตัล ขั้น 1-5
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five fishing rods side by side, tier 1 to tier 5 of the CRYSTAL set, each a little longer
and fancier: icy light-blue see-through crystal pole with white grip, a crystal reel, a heart-shaped pink crystal
float; higher tiers add crystal shards along the pole and a soft cyan glow; tier 5 has a big crystal cat head at the
tip. Same angle, clearly separated. Even soft studio lighting, 3/4 view from slightly above.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M05 `M05_rods_cosmic` — เบ็ดคอสมิก ขั้น 1-5
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five fishing rods side by side, tier 1 to tier 5 of the COSMIC set, each a little longer
and fancier: deep purple pole with a starry galaxy pattern, a reel shaped like a small planet with a ring, a star-shaped
float; higher tiers add floating little stars around the pole and a pink-purple glow; tier 5 has a moon-and-cat-ears
tip and a rainbow glowing line. Same angle, clearly separated. Even soft studio lighting, 3/4 view from slightly above.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M06 `M06_bat` — ไม้เบสบอล
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). One chunky cartoon baseball bat shown twice: from the side and in a 3/4 view. Warm light
wood with a red grip tape handle, a white paw print on the barrel and a small cat-ear shaped knob at the handle end.
Friendly toy look, not dangerous. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

# รองเท้า 8 คู่

## M07 `M07_shoes_1to4` — รองเท้าคู่ที่ 1-4
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Four single shoes in a row from left to right, each clearly different and fancier: 1
"Sneakers": a simple white sneaker with blue laces; 2 "Sport Shoes": a green-and-white sport shoe with stripes; 3
"Running Shoes": an orange running shoe with a thick bouncy sole and a paw print on the side; 4 "Bouncy Boots": a pink
boot with a big springy sole and cat ears on the back. Same 3/4 side view, clearly separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M08 `M08_shoes_5to8` — รองเท้าคู่ที่ 5-8
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Four single shoes in a row from left to right, each clearly different and fancier: 5
"Rocket Shoes": a red shoe with two small rocket boosters at the heel and orange flames; 6 "Cloud Steppers": a white
fluffy shoe made of clouds with a light-blue sole and small wings; 7 "Lightning Boots": a yellow-and-navy boot with
lightning bolt shapes and a glowing yellow sole; 8 "Comet Kicks": a purple starry shoe with a glowing comet tail behind
the heel. Same 3/4 side view, clearly separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

# ขนมแมว และกล่องสุ่ม

## M09 `M09_treats` — ขนมแมว 3 อย่าง
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Three cat treats in a row, clearly separated: 1 "Lucky Treat": a green fish-shaped biscuit
with a gold four-leaf clover on its side; 2 "Golden Fish": a shiny gold fish with a happy face and sparkles; 3
"Catnip": a small bundle of bright green catnip leaves tied with a pink ribbon in a tiny clay pot. Same 3/4 view. Even
soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M10 `M10_crates` — กล่องสุ่ม 4 แบบ (ปิดฝา) + 1 กล่องเปิด
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Four closed cat crates in a row, each a cube box with a separate lid on top, two small cat
ears on the lid and air holes shaped like paw prints on the front: 1 PAPER crate: light brown cardboard with tape and
a printed paw; 2 WOOD crate: planks of warm wood with dark corner brackets; 3 GOLD crate: shiny gold with red gem studs
on the corners and a gold cat face lock; 4 DIAMOND crate: light-blue see-through crystal with sparkling diamond corners
and a soft glow. To the far right, the gold crate again with its lid lifted off and tilted, showing it is hollow inside
with soft golden light. Same 3/4 view, clearly separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

# ดัมเบลล์ 25 ขั้น (5 ชุด x 5 ขั้น) — ผู้เล่นถือ 2 มือ

## M11 `M11_dumbbells_rubber` — ชุดยาง ขั้น 1-5
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five PAIRS of hand dumbbells in a row from left to right, steps 1 to 5 of the RUBBER set,
each pair clearly bigger and heavier than the one before (step 5 about twice the size of step 1): short grey handle,
round plates in bright red rubber with a white paw print; higher steps add more plates and a thicker handle grip. Each
pair stands on a small low wooden rack. Same 3/4 view, clearly separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M12 `M12_dumbbells_chrome` — ชุดโครเมียม ขั้น 1-5
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five PAIRS of hand dumbbells in a row, steps 1 to 5 of the CHROME set, each pair clearly
bigger and heavier than the one before: shiny silver chrome plates with blue rims and a blue grip handle; higher steps
add more plates, blue light strips and small cat-ear shapes on the outer plates. Each pair on a small low steel rack.
Same 3/4 view, clearly separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M13 `M13_dumbbells_gold` — ชุดทอง ขั้น 1-5
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five PAIRS of hand dumbbells in a row, steps 1 to 5 of the GOLD set, each pair clearly
bigger and heavier than the one before: shiny gold plates with red gems, a dark red grip; higher steps add a gold cat
face on the outer plate, more gems and sparkles. Each pair on a small low gold-trimmed rack. Same 3/4 view, clearly
separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M14 `M14_dumbbells_crystal` — ชุดคริสตัล ขั้น 1-5
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five PAIRS of hand dumbbells in a row, steps 1 to 5 of the CRYSTAL set, each pair clearly
bigger and heavier than the one before: icy light-blue see-through crystal plates with a white grip; higher steps add
crystal spikes around the plates and a soft cyan glow. Each pair on a small low icy rack. Same 3/4 view, clearly
separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M15 `M15_dumbbells_cosmic` — ชุดคอสมิก ขั้น 1-5
```
Reference sheet for 3D game props in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Five PAIRS of hand dumbbells in a row, steps 1 to 5 of the COSMIC set, each pair clearly
bigger and heavier than the one before (step 5 huge and epic): plates shaped like small planets (purple with a starry
galaxy pattern and a ring), a glowing pink grip; higher steps add orbiting little stars, a moon and a strong
pink-purple glow. Each pair on a small low starry rack. Same 3/4 view, clearly separated. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

# ลู่วิ่ง 25 ขั้น (5 ชุด x 5 ขั้น)

## M16 `M16_treadmill_basic` — ชุดธรรมดา (ขั้น 1, 3, 5)
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Three treadmills in a row from left to right, steps 1, 3 and 5 of the BASIC set, each a
little bigger and fancier: a simple light-grey frame, a dark rubber belt, a handle bar with a small screen showing a
cat face; step 3 adds green side panels; step 5 adds a cushioned handle and small cat ears on top of the screen. Same 3/4
view from the front-side, clearly separated, sized for a person to run on. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M17 `M17_treadmill_sport` — ชุดสปอร์ต (ขั้น 1, 3, 5)
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Three treadmills in a row, steps 1, 3 and 5 of the SPORT set, each a little bigger and
fancier: a sporty blue-and-white frame with orange stripes, a black belt with orange edges, a bigger screen with a
running cat; higher steps add side rails with speed-line decals and a small fan on the front. Same 3/4 view, clearly
separated, sized for a person to run on. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M18 `M18_treadmill_neon` — ชุดนีออน (ขั้น 1, 3, 5)
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Three treadmills in a row, steps 1, 3 and 5 of the NEON set, each a little bigger and
fancier: a dark navy frame with glowing cyan and pink neon strips, a belt with glowing edge lights, a screen with a
neon paw; higher steps add glowing arches over the belt and small speakers. Same 3/4 view, clearly separated, sized for
a person to run on. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M19 `M19_treadmill_gold` — ชุดทอง (ขั้น 1, 3, 5)
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Three treadmills in a row, steps 1, 3 and 5 of the GOLD set, each a little bigger and
fancier: a shiny gold frame with red velvet panels and gems, a belt with gold edges, a screen framed by a gold cat
head; higher steps add two gold pillars with crystal tops at the front and sparkles. Same 3/4 view, clearly separated,
sized for a person to run on. Even soft studio lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```

## M20 `M20_treadmill_cosmic` — ชุดคอสมิก (ขั้น 1, 3, 5)
```
Reference sheet for a 3D game prop in a cheerful kids' cat game, smooth glossy blocky toy style with softly rounded
edges (no studs anywhere). Three treadmills in a row, steps 1, 3 and 5 of the COSMIC set, each a little bigger and
fancier (step 5 epic): a deep purple frame with a starry galaxy pattern, a belt that looks like a strip of night sky
with stars, a screen with a moon cat; higher steps add a ring like a planet's around the machine, orbiting little
stars and a strong pink-purple glow. Same 3/4 view, clearly separated, sized for a person to run on. Even soft studio
lighting.
Landscape 1536x1024, plain light grey background (#E6E8EE), no floor, no text, no numbers, no logos.
```
