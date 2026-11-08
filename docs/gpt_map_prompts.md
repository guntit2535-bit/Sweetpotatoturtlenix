# A1 · ภาพทิศทางแมพ (ChatGPT)

ภาพชุดนี้เอาไว้ **เลือกสไตล์และธีมของแมพ** เท่านั้น ไม่ได้ใส่ลงเกมตรง ๆ
พอได้ภาพที่ชอบ ผมจะปั้นโมเดลจริงตามภาพใน Blender (งาน A3–A5)

## วิธีใช้
1. **ขั้นที่ 1 · เลือกสไตล์:** เปิดแชตใหม่ 2 แชต
   - แชตที่ 1 วาง prompt `L_A`
   - แชตที่ 2 วาง prompt `L_B`
   - ทั้งสองภาพเป็นล็อบบี้ผังเดียวกัน ต่างกันแค่สไตล์ ดูแล้วเลือกแบบที่ชอบ
2. **ขั้นที่ 2 · 5 โซน:** ทำต่อในแชตของสไตล์ที่เลือก (แชตเดิมเท่านั้น GPT จะได้จำสไตล์)
   - วาง `Z1` ถึง `Z5` ทีละอัน ครั้งละ 1 ภาพ
   - ถ้าเลือกสไตล์ A ให้ใช้ prompt ชุด A ถ้าเลือก B ใช้ชุด B (แต่ละ prompt มีให้ทั้งสองแบบ)
3. **เซฟไฟล์** ตามชื่อรหัส ไว้ที่ `art/source/gpt_map/`
   - `L_A.png`, `L_B.png`, `Z1.png` … `Z5.png`
   - ถ้า GPT ให้ไฟล์ .webp มาก็เก็บ .webp ไว้ได้เลย ไม่ต้องแปลง
4. ส่งภาพกลับมาให้ผม ถ้าทยอยส่งหลายรอบ บอกผมว่า "เดี๋ยวส่งอีกชุด" ได้

**ห้ามแนบภาพเกมอื่นหรือภาพอ้างอิงของลูกค้าลงในแชต** GPT มักวาดลอกตามภาพที่แนบ ตอนนี้ prompt บรรยายโทนที่ลูกค้าต้องการไว้ครบแล้ว

กติกาที่เขียนไว้ในทุก prompt แล้ว:
- ไม่มีตัวหนังสือ ไม่มีโลโก้ ไม่มี UI
- ไม่เอ่ยชื่อเกมอื่น
- ภาพแนวนอน 1536 x 1024 มุมสูงเฉียง 3/4

## ประโยคแก้เมื่อภาพเพี้ยน (วางต่อในแชตเดิม)
- มีตัวหนังสือโผล่: `Redraw the same image with absolutely no text, letters, numbers or symbols anywhere, including on signs.`
- รกเกินไป: `Redraw it simpler: fewer, bigger objects, more open checkerboard grass, clear walking paths.`
- สไตล์เพี้ยนจากภาพแรก: `Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.`
- ดูสมจริงเกินไป: `Make it less realistic: chunkier blocky cartoon shapes, brighter flat colours, toy-like.`
- แมวเหมือนตัวจริงเกินไป: `Make the cats cute blocky cartoon cats with big round eyes and simple shapes, not realistic.`

---

## ขั้นที่ 1 · ล็อบบี้ 2 สไตล์

### L_A · สไตล์ A "บล็อกเงา" (ทรงมน ผิวเงานิด ๆ แสงนุ่ม)
```
3D render of a bright, cheerful kids' game world built from chunky smooth plastic-like blocks with slightly rounded edges, bright saturated colours, a lawn of bright green checkerboard grass tiles in two shades of green in large squares, soft sunny lighting with a warm key light from the upper left and a cool blue sky fill, soft shadows, crisp clean shapes, cartoon effects such as sparkles and soft glowing light.

Scene: a high three-quarter bird's-eye view of the central lobby of a cat-catching game. In the middle, a round open plaza with a small blocky fountain. Around the plaza, 8 cat pens arranged evenly in a ring, each pen a low fenced yard with a small cat house, a blank wooden sign board in front (no text on it) and room for many cats; a few cute blocky cartoon cats with big round eyes walk inside the pens. Next to each pen, a small training corner with a dumbbell rack and a treadmill. A soft glowing ring on the ground marks the edge of the safe lobby. Outside the ring, the first area begins: suburban backyards with wooden fences, little houses and bushes, fading into the distance in every direction. A few blocky cartoon player characters walk on the plaza. Blue sky with puffy white clouds.

Landscape image, 1536 x 1024, the whole lobby ring visible inside the middle 80% of the height.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```

### L_B · สไตล์ B "การ์ตูนตัดเส้น" (สีเรียบ ตัดเส้นดำ)
```
3D cartoon render with a cel-shaded look: chunky blocky low-poly shapes with flat bright saturated colours, a thin dark outline around every object, simple two-tone shading, a lawn of bright green checkerboard grass tiles in two shades of green in large squares, sunny daylight, playful cartoon effects such as sparkles, drifting flower petals and soft glow, cheerful kids' game look.

Scene: a high three-quarter bird's-eye view of the central lobby of a cat-catching game. In the middle, a round open plaza with a small blocky fountain. Around the plaza, 8 cat pens arranged evenly in a ring, each pen a low fenced yard with a small cat house, a blank wooden sign board in front (no text on it) and room for many cats; a few cute blocky cartoon cats with big round eyes walk inside the pens. Next to each pen, a small training corner with a dumbbell rack and a treadmill. A soft glowing ring on the ground marks the edge of the safe lobby. Outside the ring, the first area begins: suburban backyards with wooden fences, little houses and bushes, fading into the distance in every direction. A few blocky cartoon player characters walk on the plaza. Blue sky with puffy white clouds.

Landscape image, 1536 x 1024, the whole lobby ring visible inside the middle 80% of the height.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```

---

## ขั้นที่ 2 · 5 โซน (ทำต่อในแชตของสไตล์ที่เลือก)

ทุกภาพจะมีแมวแอบซ่อนตามจุด 4 แบบ คือ บนหลังคา ในพุ่มไม้ หลังหิน ใต้สะพาน ให้เห็นว่าจุดซ่อนหน้าตาเป็นยังไง

### Z1 · Backyard (สวนหลังบ้าน) โซนแรก แมวธรรมดา
ชุด A:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D render of a bright, cheerful kids' game world built from chunky smooth plastic-like blocks with slightly rounded edges, bright saturated colours, bright green checkerboard grass tiles in two shades of green, soft sunny lighting, soft shadows, crisp clean shapes, cartoon sparkles.

Scene: a high three-quarter view of the first zone, "Backyard": a cosy neighbourhood of little houses with colourful roofs and their back gardens, wooden picket fences, flower beds, a clothesline with laundry, a small doghouse, round bushes, garden rocks, a narrow stream with a small wooden footbridge. Cute blocky cartoon cats with big round eyes are hiding in four kinds of places: one sitting on a house roof, one peeking out of a round bush (only its head and ears), one peeking from behind a garden rock, one under the wooden footbridge. Open checkerboard grass paths between the gardens so players can run through. Blue sky, puffy clouds.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```
ชุด B:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D cartoon render with a cel-shaded look: chunky blocky low-poly shapes, flat bright saturated colours, a thin dark outline around every object, simple two-tone shading, bright green checkerboard grass tiles in two shades of green, sunny daylight, cartoon sparkles.

Scene: a high three-quarter view of the first zone, "Backyard": a cosy neighbourhood of little houses with colourful roofs and their back gardens, wooden picket fences, flower beds, a clothesline with laundry, a small doghouse, round bushes, garden rocks, a narrow stream with a small wooden footbridge. Cute blocky cartoon cats with big round eyes are hiding in four kinds of places: one sitting on a house roof, one peeking out of a round bush (only its head and ears), one peeking from behind a garden rock, one under the wooden footbridge. Open checkerboard grass paths between the gardens so players can run through. Blue sky, puffy clouds.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```

### Z2 · Town Market (ตลาดในเมือง)
ชุด A:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D render of a bright, cheerful kids' game world built from chunky smooth plastic-like blocks with slightly rounded edges, bright saturated colours, bright green checkerboard grass tiles in two shades of green between paved squares, soft sunny lighting, soft shadows, crisp clean shapes, cartoon sparkles.

Scene: a high three-quarter view of the second zone, "Town Market": a lively little market town with rows of market stalls under striped awnings in red, yellow and blue, stacks of fruit and fish crates, hanging paper lanterns, shop buildings with flat rooftops and chimneys, potted plants, a small square with a round fountain, a canal crossed by a stone arch bridge. Cute blocky cartoon cats with big round eyes are hiding in four kinds of places: one on a shop rooftop, one peeking out of a round hedge bush, one behind a big rock by the canal, one under the stone bridge. Open paths between the stalls so players can run through. Blue sky, puffy clouds.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```
ชุด B:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D cartoon render with a cel-shaded look: chunky blocky low-poly shapes, flat bright saturated colours, a thin dark outline around every object, simple two-tone shading, bright green checkerboard grass tiles in two shades of green between paved squares, sunny daylight, cartoon sparkles.

Scene: a high three-quarter view of the second zone, "Town Market": a lively little market town with rows of market stalls under striped awnings in red, yellow and blue, stacks of fruit and fish crates, hanging paper lanterns, shop buildings with flat rooftops and chimneys, potted plants, a small square with a round fountain, a canal crossed by a stone arch bridge. Cute blocky cartoon cats with big round eyes are hiding in four kinds of places: one on a shop rooftop, one peeking out of a round hedge bush, one behind a big rock by the canal, one under the stone bridge. Open paths between the stalls so players can run through. Blue sky, puffy clouds.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```

### Z3 · Forest (ป่า) ธีมสวนญี่ปุ่น ตามตัวอย่างของลูกค้า
ชุด A:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D render of a bright, cheerful kids' game world built from chunky smooth plastic-like blocks with slightly rounded edges, bright saturated colours, bright green checkerboard grass tiles in two shades of green, soft sunny lighting, soft shadows, crisp clean shapes, drifting pink flower petals and soft glowing light.

Scene: a high three-quarter view of the third zone, "Forest", themed as a peaceful Japanese-style garden forest: rows of red wooden gate arches over a stone path, blocky trees with pink blossom canopies, tall green bamboo groves, a cliff with two cartoon waterfalls falling into a clear blue pond, stepping stones, a red arched wooden bridge over the stream, mossy rocks, stone lanterns. Cute blocky cartoon cats with big round eyes are hiding in four kinds of places: one on the roof of a small wooden shrine pavilion, one peeking out of a round bush, one behind a mossy rock, one under the red arched bridge. Open grass paths so players can run through. Blue sky, puffy clouds.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```
ชุด B:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D cartoon render with a cel-shaded look: chunky blocky low-poly shapes, flat bright saturated colours, a thin dark outline around every object, simple two-tone shading, bright green checkerboard grass tiles in two shades of green, sunny daylight, drifting pink flower petals and soft glow.

Scene: a high three-quarter view of the third zone, "Forest", themed as a peaceful Japanese-style garden forest: rows of red wooden gate arches over a stone path, blocky trees with pink blossom canopies, tall green bamboo groves, a cliff with two cartoon waterfalls falling into a clear blue pond, stepping stones, a red arched wooden bridge over the stream, mossy rocks, stone lanterns. Cute blocky cartoon cats with big round eyes are hiding in four kinds of places: one on the roof of a small wooden shrine pavilion, one peeking out of a round bush, one behind a mossy rock, one under the red arched bridge. Open grass paths so players can run through. Blue sky, puffy clouds.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```

### Z4 · Snow Mountain (ภูเขาหิมะ)
ชุด A:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D render of a bright, cheerful kids' game world built from chunky smooth plastic-like blocks with slightly rounded edges, bright saturated colours, the checkerboard ground now in two shades of snowy white and pale blue squares with patches of green checkerboard grass, crisp sunny lighting, soft blue shadows, crisp clean shapes, sparkling snowflakes and glowing ice crystals.

Scene: a high three-quarter view of the fourth zone, "Snow Mountain": snowy blocky hills rising to a big mountain in the back, blocky pine trees with snow on top, cosy wooden cabins with thick snow on the roofs, ice blocks and glowing blue crystals, a frozen lake crossed by a wooden plank bridge, a friendly snowman, icicles on rocks. Cute blocky cartoon cats with big round eyes and fluffy winter fur are hiding in four kinds of places: one on a snowy cabin roof, one peeking out of a snow-covered bush, one behind an icy rock, one under the plank bridge. Open paths through the snow so players can run through. Clear blue sky.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```
ชุด B:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D cartoon render with a cel-shaded look: chunky blocky low-poly shapes, flat bright saturated colours, a thin dark outline around every object, simple two-tone shading, the checkerboard ground now in two shades of snowy white and pale blue squares with patches of green checkerboard grass, crisp sunny daylight, sparkling snowflakes and glowing ice crystals.

Scene: a high three-quarter view of the fourth zone, "Snow Mountain": snowy blocky hills rising to a big mountain in the back, blocky pine trees with snow on top, cosy wooden cabins with thick snow on the roofs, ice blocks and glowing blue crystals, a frozen lake crossed by a wooden plank bridge, a friendly snowman, icicles on rocks. Cute blocky cartoon cats with big round eyes and fluffy winter fur are hiding in four kinds of places: one on a snowy cabin roof, one peeking out of a snow-covered bush, one behind an icy rock, one under the plank bridge. Open paths through the snow so players can run through. Clear blue sky.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```

### Z5 · Sky Islands (เกาะลอยฟ้า) โซนสุดท้าย แมวหายากที่สุด
ชุด A:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D render of a bright, cheerful kids' game world built from chunky smooth plastic-like blocks with slightly rounded edges, bright saturated colours, bright green checkerboard grass tiles in two shades of green on top of every island, warm golden sunny lighting, soft shadows, crisp clean shapes, magical sparkles, glowing crystals and a soft rainbow.

Scene: a high three-quarter view of the fifth and last zone, "Sky Islands": a group of floating blocky islands high above a sea of fluffy white clouds, joined by wooden rope bridges, cartoon waterfalls pouring off the island edges into the clouds, small white-and-gold pavilions with curved roofs, giant glowing purple and pink crystals, floating stepping stones, a rainbow arching across the sky. Cute blocky cartoon cats with big round eyes, some with tiny wings or a soft glowing aura, are hiding in four kinds of places: one on a pavilion roof, one peeking out of a round bush, one behind a glowing crystal rock, one under a rope bridge. Clear walkable paths across the islands. Bright sky.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```
ชุด B:
```
Keep exactly the same art style, colours, lighting and camera angle as the first image in this chat.

3D cartoon render with a cel-shaded look: chunky blocky low-poly shapes, flat bright saturated colours, a thin dark outline around every object, simple two-tone shading, bright green checkerboard grass tiles in two shades of green on top of every island, warm golden daylight, magical sparkles, glowing crystals and a soft rainbow.

Scene: a high three-quarter view of the fifth and last zone, "Sky Islands": a group of floating blocky islands high above a sea of fluffy white clouds, joined by wooden rope bridges, cartoon waterfalls pouring off the island edges into the clouds, small white-and-gold pavilions with curved roofs, giant glowing purple and pink crystals, floating stepping stones, a rainbow arching across the sky. Cute blocky cartoon cats with big round eyes, some with tiny wings or a soft glowing aura, are hiding in four kinds of places: one on a pavilion roof, one peeking out of a round bush, one behind a glowing crystal rock, one under a rope bridge. Clear walkable paths across the islands. Bright sky.

Landscape image, 1536 x 1024.
No text, no letters, no numbers, no logo, no user interface, no watermark, no frame. Do not draw any existing game, brand or character.
```
