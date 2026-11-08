# ไอคอนเกม 1 + หน้าปก 4 ด้วย GPT (งาน 2.24) + คำอธิบายเกม EN / TH

## วิธีใช้
1. เปิดแชทใหม่ใน ChatGPT แล้ว **แนบ 3 ภาพ** จากโฟลเดอร์เกม (เป็นงานของเราเอง):
   - `art/preview/cats_lineup.jpg` (แมวจริงในเกม: Basic ถึง Mythical + ร่าง Gold / Rainbow / Glow)
   - `art/preview/carry_ingame.jpg` (ผู้เล่นชูแมวเหนือหัวในเกมจริง)
   - `art/source/gpt_map/L_A.webp` (หน้าตาแผนที่ที่ผ่านแล้ว)

   แล้วพิมพ์บรรทัดนี้ก่อน:
   `These are pictures of my own game. Draw everything in exactly this smooth blocky style (no studs) for the next images.`
2. วาง prompt ทีละข้อ (ข้อ 1 ไอคอน, ข้อ 2-5 หน้าปก) ในแชทเดิม ภาพจะได้สไตล์เดียวกัน
3. ได้ภาพแล้วตั้งชื่อ `icon`, `thumb1` ... `thumb4` (นามสกุลตามที่ GPT ส่งมา เช่น .png / .webp) ใส่ที่
   `art/source/gpt_store/` แล้วบอกผม ผมย่อ / ครอปเป็นขนาด Roblox: ไอคอน 512 x 512, หน้าปก 1920 x 1080

ขนาดที่ขอ GPT
- ไอคอน: **1024 x 1024 สี่เหลี่ยมจัตุรัส**
- หน้าปก: **1536 x 1024 แนวนอน** (ผมครอปบน-ล่างนิดหน่อยให้เป็น 16:9) ทุก prompt สั่งให้วางของสำคัญไว้กลางภาพแล้ว

กติกาของ Roblox ที่เขียนไว้ใน prompt แล้ว
- ไม่มีไอคอน Robux, ไม่มีคำว่า "free", ไม่มีลูกศร / วงกลมแดงชี้หลอก, ไม่มีโลโก้ Roblox หรือเกมอื่น
- ภาพต้องตรงกับสิ่งที่มีในเกมจริง (ตกแมวด้วยเบ็ด, ชูแมวกลับคอก, ตีด้วยไม้เบสบอลให้แมวหลุด, ยกน้ำหนัก,
  แมว Mythical มีปีก + วงแหวน, ร่าง Gold / Rainbow / Glow, 5 โซน)
- เด็กเล่นได้: ตีแล้วมีแค่ดาวการ์ตูน ไม่มีเลือด ไม่มีใครเจ็บ

เคล็ดลับ (พิมพ์ต่อในแชทเดิมเมื่อภาพเพี้ยน)
- ตัวหนังสือเพี้ยน: `Fix the title text: exactly "SWEETPOTATOTURTLENIX", nothing else written.`
- รกเกิน: `Simpler: fewer objects, bigger main characters, more empty sky.`
- มีปุ่มกลม (studs) โผล่มา: `Remove every round stud: all surfaces are smooth and flat, like the pictures I attached.`
- แมวไม่เหมือนในเกม: `Make the cats exactly like the cats in the first picture I attached: cube head, triangle ears, small square eyes.`

---

## 1. `icon` — ไอคอนเกม (สี่เหลี่ยม)
แมวส้มตัวโตถูกเบ็ดเกี่ยวดึงขึ้นมาจากพุ่มไม้ ประกายวิ้ง ไม่มีตัวหนังสือ (ไอคอนเล็ก อ่านไม่ออกอยู่ดี)
```
A square game icon for a cheerful kids' cat-catching game. The whole world is made of smooth glossy blocky shapes
with flat surfaces (no studs anywhere), bright saturated colours.
Centre, big and filling most of the frame: a cute blocky orange tabby cat with a cube-shaped head, two triangular ears
with pink insides, small square black eyes with a white shine dot, pink blush squares on the cheeks, a tiny pink nose
and a wide happy open smile, a box-shaped body with darker orange stripes and a cream belly, four short square legs
and a short blocky tail. The cat is being lifted out of a round green blocky bush by a fishing line: the line is
hooked gently onto a small red collar (no hook in the cat), and the cat floats up surprised and happy with its paws
out. A curved wooden fishing rod tip comes in from the top-right corner. Small yellow sparkles and two floating gold
coins around the cat. Background: a bright turquoise sky with one puffy white blocky cloud and green checkered grass
in two shades of green at the bottom.
Style: bright, saturated, high-contrast 3D render, soft studio light from the upper left, a cool blue rim light from
behind, crisp clean edges that read clearly even at 100 x 100 pixels, the cat's face is the clear focal point.
Square 1024x1024, the art fills the whole square (no border, no frame, no rounded corners, no white margin). No text,
no letters, no numbers, no logos, no currency symbols, no arrows.
```

## 2. `thumb1` — หน้าปกหลัก: ตกแมว + ชื่อเกม
ผู้เล่นเหวี่ยงเบ็ดดึงแมวออกจากหลังคา / พุ่มไม้ในโซนสวนหลังบ้าน แมวอีกหลายตัวแอบซ่อน + ชื่อเกมตัวใหญ่
```
A wide promotional thumbnail for a cheerful kids' cat-catching game. The whole world is made of smooth glossy blocky
shapes with flat surfaces (no studs anywhere): a sunny backyard neighbourhood with green checkered grass in two shades
of green, small blocky houses with red and blue roofs, white picket fences, round green bushes and a turquoise sky with
puffy white blocky clouds.
Foreground, left: a blocky toy-figure kid player with a square head, brown hair, a yellow T-shirt and blue pants,
leaning back with a big happy grin and pulling a bendy wooden fishing rod with both hands. The fishing line arcs to
the centre-right, where a cute blocky white-and-grey tabby cat (cube head, triangular ears with pink insides, small
square black eyes with white shine dots, pink blush squares, a happy surprised open mouth) is being pulled up out of a
round green bush, its little paws waving, the line looped around its small blue collar. Hidden around the scene,
easy to spot: a ginger cat peeking from a red roof, a black-and-white cat peeking from behind a fence post, a cream
cat's ears poking out of a bush.
At the top: the title "SWEETPOTATOTURTLENIX" in huge chunky rounded letters, warm orange-to-yellow with a thick dark
navy outline, slightly arched, with a small cat paw print beside it.
Style: bright, saturated, cheerful 3D render, slightly low camera, warm sunlight from the upper left, crisp clean
shapes. Keep the title and the main characters inside the middle 80% of the height (the top and bottom edges may be
cropped). Landscape 1536x1024. No other text, no logos, no currency symbols, no arrows, no red circles.
```

## 3. `thumb2` — หน้าปก 2: ชูแมววิ่งกลับคอก + โดนตีด้วยไม้เบสบอล
ผู้เล่นชูแมวเหนือหัววิ่งกลับคอก อีกคนเหวี่ยงไม้เบสบอลฟองน้ำ มีดาวการ์ตูน + "BONK AND GRAB!"
```
A wide promotional thumbnail for a cheerful kids' cat-catching game. The whole world is made of smooth glossy blocky
shapes with flat surfaces (no studs anywhere): a bright town market street with green checkered grass in two shades of
green, colourful stalls with striped awnings (red, yellow, purple, blue), fruit crates and lantern posts, a turquoise
sky.
Centre-left: a blocky toy-figure kid player (square head, black hair, red hoodie, grey pants) running toward the
viewer, holding a big fluffy purple blocky cat high above the head with both arms straight up, the cat looking
excited with a wide open smile. Right: a second blocky kid player (orange hair, green T-shirt, blue shorts) mid-swing
with a chunky cartoon baseball bat, a playful cheeky face; where the swing meets the runner's back there is a bright
yellow cartoon "impact star" burst with small white stars, nobody hurt, everyone smiling. A cute blocky ginger cat
is popping loose in the air between them, also smiling. Far behind on the left: a wooden pen with a big sign reading
"YOUR PEN" and a few happy cats inside.
Top right: the words "BONK AND GRAB!" in huge chunky rounded white letters with a thick dark navy outline, slightly
tilted, with small yellow stars around them.
Style: bright, saturated, action-packed but friendly 3D render, slightly low camera, motion lines, warm light, crisp
clean shapes, kid-friendly, no blood. Keep the words and the three characters inside the middle 80% of the height.
Landscape 1536x1024. No other text, no logos, no currency symbols, no arrows, no red circles.
```

## 4. `thumb3` — หน้าปก 3: แมวหายาก (Mythical + ร่าง Gold / Rainbow / Glow)
แมว Mythical มีปีก + วงแหวน ลอยในลำแสงบนเกาะลอยฟ้า แมวร่างทอง / สีรุ้ง / เรืองแสงล้อมรอบ + "400 CATS TO COLLECT!"
```
A wide promotional thumbnail for a cheerful kids' cat-catching game. The whole world is made of smooth glossy blocky
shapes with flat surfaces (no studs anywhere): floating sky islands with green checkered grass, white-and-gold
pavilions with blue roofs, purple and pink crystals, small waterfalls pouring off the island edges, a rainbow and a
soft sea of white clouds below.
Centre: a bigger cute blocky lavender cat with small white feathered wings and a glowing golden halo, standing on top
of a tall pillar of pink light that rises into the sky, sparkles all around, big shiny blue square eyes, pink blush
squares and a happy smile. Around it on the island, three more cute blocky cats with cube heads and triangular ears,
each in a special finish: on the left a cat made of shiny GOLD with gold sparkles; in front a RAINBOW cat with
rainbow stripes across its body; on the right a GLOWING neon-cyan cat with a soft glow aura. All have small square
black eyes with white shine dots, pink blush squares and happy smiles.
Top: the words "400 CATS TO COLLECT!" in huge chunky rounded white letters with a thick dark navy outline, the number
"400" in gold.
Style: bright, saturated, magical 3D render, warm golden light from the halo and the light pillar, sparkles, crisp
clean shapes. Keep the words and the cats inside the middle 80% of the height. Landscape 1536x1024. No other text, no
logos, no currency symbols, no arrows, no red circles.
```

## 5. `thumb4` — หน้าปก 4: ฝึกให้แข็งแรง จับแมวยักษ์
ผู้เล่นยกดัมเบลล์หน้าคอก แมว Secret ตัวยักษ์ข้างหลัง + "GET STRONG, CATCH GIANT CATS!"
```
A wide promotional thumbnail for a cheerful kids' cat-catching game. The whole world is made of smooth glossy blocky
shapes with flat surfaces (no studs anywhere): a sunny lobby plaza with green checkered grass in two shades of green,
colourful wooden cat pens with fences, a blue treadmill and a weight bench beside a pen, a turquoise sky.
Left foreground: a blocky toy-figure kid player (square head, brown hair, blue tank top, black shorts) lifting a big
chunky dumbbell over the head with a proud determined grin, little sweat-drop sparkles, a floating "+0.1 kg" in
chunky green numbers beside the player. Right and behind: a GIANT cute blocky cat four times as tall as the player,
dark navy with white socks, a glowing golden halo and a soft rainbow aura, cube head with triangular ears with pink
insides, big shiny square eyes and a happy smile, looking down at the player playfully.
Top: the words "GET STRONG, CATCH GIANT CATS!" in huge chunky rounded white letters with a thick dark navy outline, the
word "GIANT" in gold.
Style: bright, saturated, fun 3D render, slightly low camera to show the giant cat's size, warm light, crisp clean
shapes. Keep the words and both characters inside the middle 80% of the height. Landscape 1536x1024. No other text
except "+0.1 kg", no logos, no currency symbols, no arrows, no red circles.
```

---

## คำอธิบายเกม (ใส่ใน Creator Dashboard: ชื่อ + คำอธิบาย)

ชื่อเกม: **Sweetpotatoturtlenix** (ทั้ง EN และ TH; ลูกค้ายืนยันแล้ว)

### English (ภาษาหลัก)
```
🐱 Cats are hiding all over the map! Fish them out with your rod and carry them home to your pen.

🎣 CATCH – Cast your rod at a hidden cat and keep it in the green zone to reel it in. Other players can go for the same cat, so be quick!
🏃 CARRY HOME – Hold your cat over your head and run back to your pen. Watch out: other players can bonk you with a baseball bat to knock it loose... and grab it!
💰 EARN – Every cat in your pen makes money every second, even while you are away.
🏋️ TRAIN – Lift weights for Strength (heavier, rarer cats) and run on the treadmill for Speed.
🗺️ EXPLORE – 5 zones: Backyard, Town Market, Forest, Snow Mountain and the Sky Islands.
✨ 400 CATS – Basic, Rare, Epic, Legendary, Mythical and Secret, plus Gold, Rainbow and Glow mutations. Fill your Collection Book!
⭐ EVENTS – A Mythical or Secret cat appears for everyone: race the whole server to catch it!
🎁 Daily rewards, quests, playtime gifts, crates, rebirths, trading and leaderboards.

Language: English / ไทย (Settings).
```

### ไทย (ถ้าต้องการใส่คำแปล: Creator Dashboard → Localization → Thai)
```
🐱 แมวซ่อนอยู่ทั่วแผนที่! ใช้เบ็ดตกแมวออกมาแล้วแบกกลับไปที่คอกของคุณ

🎣 จับแมว – เหวี่ยงเบ็ดใส่แมวที่ซ่อนอยู่ แล้วคุมแมวให้อยู่ในช่องสีเขียวเพื่อดึงขึ้นมา ผู้เล่นคนอื่นแย่งแมวตัวเดียวกันได้ ต้องไว!
🏃 แบกกลับบ้าน – ชูแมวเหนือหัวแล้ววิ่งกลับคอก ระวัง: ผู้เล่นคนอื่นเอาไม้เบสบอลตีให้แมวหลุดแล้วแย่งไปได้!
💰 หาเงิน – แมวทุกตัวในคอกสร้างเงินทุกวินาที แม้ตอนออฟไลน์
🏋️ ฝึก – ยกน้ำหนักเพิ่มพลัง (จับแมวที่หนักและหายากขึ้น) และวิ่งลู่เพิ่มความเร็ว
🗺️ สำรวจ – 5 โซน: สวนหลังบ้าน ตลาดในเมือง ป่า ภูเขาหิมะ และเกาะลอยฟ้า
✨ แมว 400 แบบ – Basic, Rare, Epic, Legendary, Mythical และ Secret พร้อมร่าง Gold, Rainbow, Glow สะสมให้ครบในสมุดสะสม!
⭐ อีเวนต์ – แมว Mythical หรือ Secret โผล่มาให้ทั้งเซิร์ฟเวอร์ แข่งกันจับ!
🎁 รางวัลรายวัน ภารกิจ ของขวัญตามเวลาเล่น กล่องสุ่ม รีเบิร์ธ แลกเปลี่ยนแมว และกระดานอันดับ

ภาษา: English / ไทย (ในตั้งค่า)
```
