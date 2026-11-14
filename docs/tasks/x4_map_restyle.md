# X4: map restyle, look B "pixel voxel" + look A's LEGO flowers

Developer, 2026-11-15: "ลูกค้าเลือกBแต่ดอกไม้ลูกค้าขอเอาดอกไม้แบบA". The layout (Config.World, BuildMap) stays; every
decoration gets the new look. Reference renders: art/preview/mapstyle/style_B.png (the look) and style_A.png (the
flowers). Blender source of the look: art/blender/mapstyle.py.

## How it is built
- Props are voxel meshes made in Blender (art/blender/voxprops.py), exported like the items: family "MapProps" in
  art/blender/items_export.py -> art/export/MapProps.fbx + manifest -> src/shared/ItemModelData.luau. The developer
  imports MapProps.fbx into ReplicatedStorage.ItemModels.MapProps (Creator = the group), like the crates.
- MapKit uses a prop mesh when it is imported (Kit.mesh: an anchored clone sized from ItemModelData), else the old
  part-built prop, so the map still builds before the import. Hiding spots (bushes, rocks) stay where they are.
- One mesh per prop variant, faces merged (light on phones, like the voxel cats).

## Stages
1. S1 core kit: trees (3), blossom trees (2), pines (2) + snowy pines (2), bushes (2) + berry + snowy, rocks (2) + mossy
   + snowy, LEGO flowers (7 colours), grass tufts (2), fence post + rail, pen gate, cat house, lamp. Then the map is
   rebuilt with them (props only; the layout and spots stay).
2. S2 ground: pixel-noise textures (3 greens per zone colour, path, dirt edge) on the ground tiles with the LEGO studs
   (images the developer uploads to the group).
3. S3 water (revision 4 item 11): creeks and ponds as Terrain water about 5.5 studs deep in a cut trench; walls clear
   of the gate pillars (item 14).
4. S4 zone buildings and small props in the same look (houses, shops, stalls, cabin, pavilion, torii, stone lanterns,
   snowman, crystals, barrels, crates, mushrooms, logs ...).
5. S5 check every zone in Studio (captures), then a client page.
