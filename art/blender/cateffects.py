"""The effect around each Mythical / Secret cat (round 2), keyed by effectKey from art/source/cat_designs.json.
STYLE[key] = one or more catparts.fx() calls (layout, kind of item, colours, count, size, glow). The Blender sheets use
it for the preview; the game builds the same effect from the same table (V5h: orbiting items + particles).
"""
from catparts import fx

FIRE = [(255, 120, 40), (255, 200, 60)]
ICE = [(180, 230, 255), (235, 250, 255)]
GOLDS = [(255, 205, 60), (255, 240, 170)]
RAINBOW = [(255, 80, 80), (255, 170, 40), (255, 230, 60), (90, 210, 100), (70, 160, 255), (170, 100, 255)]
PURPLE = [(170, 90, 255), (220, 150, 255)]
GREEN = [(110, 220, 90), (170, 240, 120)]


def S(layout, kind, cols, n=8, s=0.4, emit=2.0, z=(0.6, 3.6), r=None, seed=3):
    return dict(layout=layout, kind=kind, cols=cols, n=n, s=s, emit=emit, z=z, r=r, seed=seed)


STYLE = {
    # Mythical
    "dragon_flames": [S("orbit", "flame", FIRE, 8, 0.5, 3.0)],
    "fire_ring": [S("orbit", "flame", FIRE, 14, 0.55, 3.0, z=(0.3, 0.6))],
    "frost_shards": [S("orbit", "gem", ICE, 9, 0.45, 1.2)],
    "phoenix_feathers": [S("orbit", "feather", FIRE, 9, 0.6, 1.5)],
    "rainbow_stars": [S("orbit", "star", RAINBOW, 6, 0.5, 1.5)],
    "cloud_puffs": [S("ground", "cloud", [(255, 255, 255), (225, 240, 255)], 6, 0.7, 0.3)],
    "wind_feathers": [S("orbit", "feather", [(250, 245, 230), (210, 225, 255)], 9, 0.55, 0.4)],
    "bubbles_up": [S("rise", "bubble", [(200, 240, 255), (230, 250, 255)], 9, 0.45, 0.3, z=(0.8, 5.0))],
    "water_swirl": [S("orbit", "drop", [(70, 160, 255), (140, 210, 255)], 12, 0.45, 0.4, z=(0.4, 2.0))],
    "snowfall": [S("above", "flake", ICE, 8, 0.45, 0.8), S("orbit", "flake", ICE, 6, 0.35, 0.8, seed=5)],
    "rocks_orbit": [S("orbit", "rock", [(140, 140, 150), (110, 120, 110)], 7, 0.55, 0.0)],
    "crystal_orbit": [S("orbit", "gem", [(150, 220, 255), (200, 160, 255)], 7, 0.55, 1.5)],
    "fairy_dust": [S("orbit", "spark", [(255, 170, 220), (190, 255, 190)], 12, 0.35, 2.5)],
    "leaf_swirl": [S("orbit", "leaf", GREEN, 10, 0.5, 0.3)],
    "bats_orbit": [S("orbit", "bat", [(70, 50, 90)], 5, 0.8, 0.0, z=(2.0, 4.5))],
    "moon_orbit": [S("orbit", "moon", [(255, 235, 150)], 3, 0.8, 1.5, z=(3.0, 4.6))],
    "green_fog": [S("ground", "cloud", [(170, 230, 150), (200, 240, 180)], 7, 0.8, 0.5)],
    "wisps": [S("orbit", "ball", [(120, 200, 255), (180, 230, 255)], 6, 0.45, 3.0)],
    "sand_swirl": [S("orbit", "cube", [(230, 200, 140), (210, 175, 110)], 16, 0.18, 0.2, z=(0.3, 3.2))],
    "sparks": [S("orbit", "spark", [(120, 230, 255), (255, 240, 120)], 10, 0.35, 3.0)],
    "scan_ring": [S("ring", "", [(80, 230, 255)], 22, 0.3, 3.0, z=(1.6,))],
    "ufo_orbit": [S("orbit", "ufo", [(255, 120, 200), (120, 255, 160)], 3, 0.9, 1.0, z=(3.0, 4.5))],
    "tractor_beam": [S("rise", "cube", [(150, 255, 150)], 6, 0.2, 2.0, z=(0.3, 2.0))],
    "lanterns": [S("orbit", "lantern", [(255, 150, 40)], 5, 0.6, 1.5)],
    "potion_bubbles": [S("rise", "bubble", PURPLE, 8, 0.45, 0.8, z=(1.0, 5.0))],
    "blizzard": [S("orbit", "flake", ICE, 14, 0.4, 0.8)],
    "lightning": [S("orbit", "bolt", [(255, 240, 80), (180, 220, 255)], 5, 0.8, 3.0)],
    "foxfire": [S("orbit", "flame", [(90, 170, 255), (170, 220, 255)], 7, 0.5, 3.0)],
    "gold_water": [S("orbit", "drop", GOLDS, 10, 0.4, 1.0)],
    "gold_feathers": [S("orbit", "feather", GOLDS, 9, 0.55, 1.0)],
    "embers": [S("rise", "cube", [(255, 90, 40), (255, 160, 60)], 12, 0.18, 3.0, z=(0.5, 5.0))],
    "emerald_bubbles": [S("rise", "bubble", [(60, 220, 140), (140, 255, 190)], 8, 0.45, 0.8, z=(0.8, 5.0))],
    "flowers_bloom": [S("ground", "flower", [(255, 130, 170), (255, 220, 80), (170, 130, 255)], 8, 0.6, 0.2)],
    "spores": [S("rise", "ball", [(150, 255, 230), (200, 255, 160)], 12, 0.2, 3.0, z=(0.6, 5.0))],
    "lava_heat": [S("ground", "drop", [(255, 110, 30)], 6, 0.45, 2.5), S("above", "cloud", [(200, 190, 190)], 3, 0.5, 0.0)],
    "cloud_ring": [S("orbit", "cloud", [(255, 255, 255), (220, 235, 255)], 8, 0.6, 0.3, z=(1.0, 1.6))],
    "waves": [S("ring", "", [(60, 150, 255), (140, 210, 255)], 24, 0.4, 0.6, z=(0.15,))],
    "stone_dust": [S("orbit", "cube", [(150, 150, 160), (120, 120, 130)], 14, 0.18, 0.0)],
    "magic_smoke": [S("rise", "cloud", [(170, 110, 255), (255, 210, 90)], 6, 0.6, 1.0, z=(0.6, 4.0))],
    "purple_aura": [S("ring", "", PURPLE, 20, 0.35, 3.0, z=(0.15,)), S("orbit", "spark", PURPLE, 6, 0.35, 3.0)],
    "drum_waves": [S("ring", "", [(255, 60, 60), (255, 140, 120)], 22, 0.4, 2.0, z=(0.12,))],
    "confetti": [S("orbit", "pixel", RAINBOW, 16, 0.28, 0.2)],
    "hearts": [S("rise", "heart", [(255, 90, 140), (255, 160, 200)], 6, 0.5, 1.0, z=(2.0, 5.0))],
    "slime_drops": [S("orbit", "drop", [(120, 230, 90), (170, 255, 140)], 8, 0.45, 0.6)],
    "candy_orbit": [S("orbit", "candy", [(255, 120, 180), (120, 200, 255), (255, 220, 80)], 7, 0.6, 0.3)],
    "gears_orbit": [S("orbit", "gear", [(210, 170, 70), (180, 140, 60)], 6, 0.6, 0.0)],
    "steam_puffs": [S("above", "cloud", [(245, 245, 250)], 4, 0.55, 0.2)],
    "glitch": [S("orbit", "pixel", [(170, 90, 255), (60, 255, 230), (255, 80, 200)], 16, 0.3, 2.5)],
    "neon_rings": [S("ring", "", [(255, 60, 200)], 20, 0.3, 3.5, z=(0.5,)), S("ring", "", [(60, 230, 255)], 20, 0.3, 3.5, z=(2.0,), r=2.4)],
    "soap_bubbles": [S("orbit", "bubble", RAINBOW, 9, 0.55, 0.3)],
    # Secret
    "sparkle_aura": [S("orbit", "spark", GOLDS, 12, 0.4, 3.0)],
    "sun_rays": [S("back", "", [(255, 190, 40), (255, 230, 120)], 16, 0.9, 2.5, r=2.3)],
    "moon_stars": [S("orbit", "moon", [(230, 235, 255)], 3, 0.8, 1.5, z=(2.5, 4.5)), S("orbit", "star", [(255, 240, 160)], 6, 0.35, 2.0, seed=7)],
    "star_orbit": [S("orbit", "star", GOLDS, 6, 0.75, 2.5)],
    "nebula_swirl": [S("orbit", "cloud", [(200, 110, 255), (255, 120, 200), (110, 150, 255)], 9, 0.6, 1.5)],
    "singularity": [S("ring", "", [(130, 60, 220), (60, 20, 90)], 24, 0.4, 2.5, z=(1.6,)), S("orbit", "spark", PURPLE, 8, 0.3, 3.0)],
    "clock_faces": [S("orbit", "clock", [(255, 240, 200)], 5, 0.8, 1.2)],
    "storm": [S("above", "cloud", [(110, 115, 130), (140, 145, 160)], 5, 0.8, 0.0), S("orbit", "bolt", [(255, 240, 80)], 4, 0.8, 3.0)],
    "water_orbit": [S("orbit", "drop", [(60, 150, 255), (150, 220, 255)], 16, 0.4, 0.6)],
    "floating_islands": [S("orbit", "rock", [(120, 100, 80), (100, 160, 80)], 5, 0.8, 0.0)],
    "fire_storm": [S("orbit", "flame", FIRE, 16, 0.6, 3.0)],
    "big_snowflakes": [S("orbit", "flake", ICE, 6, 0.9, 1.2)],
    "wind_trails": [S("orbit", "feather", [(170, 255, 220), (220, 255, 240)], 12, 0.6, 0.8)],
    "white_feathers": [S("orbit", "feather", [(255, 255, 255), (240, 240, 230)], 10, 0.6, 0.3)],
    "shadow_wisps": [S("orbit", "cloud", [(70, 40, 100), (120, 70, 170)], 8, 0.6, 0.6)],
    "rainbow_trail": [S("ring", "", RAINBOW, 24, 0.4, 2.0, z=(1.2,))],
    "prism_shards": [S("orbit", "gem", RAINBOW, 7, 0.8, 1.5)],
    "gold_clouds": [S("orbit", "cloud", GOLDS, 8, 0.6, 1.0)],
    "star_spray": [S("above", "star", [(255, 240, 160), (180, 220, 255)], 8, 0.45, 2.5)],
    "pink_mist": [S("orbit", "cloud", [(255, 150, 210), (150, 220, 255)], 10, 0.6, 1.5)],
    "comet_tail": [S("orbit", "spark", [(180, 230, 255), (255, 255, 255)], 14, 0.35, 3.0)],
    "moons_orbit": [S("orbit", "ball", [(200, 200, 210), (230, 220, 200), (180, 190, 220)], 3, 0.8, 0.5, z=(1.5, 4.0))],
    "aurora_curtain": [S("back", "", [(80, 255, 170), (120, 200, 255), (200, 120, 255)], 18, 0.8, 2.5, r=2.4)],
    "dream_bubbles": [S("orbit", "bubble", [(220, 200, 255), (200, 230, 255)], 8, 0.6, 0.6), S("orbit", "star", [(255, 240, 160)], 5, 0.3, 2.0, seed=9)],
    "portals": [S("orbit", "portal", [(80, 230, 255), (170, 90, 255)], 3, 1.2, 3.0, z=(1.0, 3.0))],
    "code_rise": [S("rise", "pixel", [(60, 255, 230), (120, 200, 255)], 14, 0.25, 3.0, z=(0.5, 5.0))],
    "jet_flames": [S("orbit", "flame", [(90, 180, 255), (255, 200, 80)], 6, 0.6, 3.0, z=(0.8, 2.0))],
    "diamond_rain": [S("above", "gem", [(220, 245, 255), (200, 220, 255)], 10, 0.4, 1.5)],
    "golden_sand": [S("ring", "", GOLDS, 26, 0.3, 1.5, z=(0.4,)), S("orbit", "cube", GOLDS, 12, 0.16, 1.0)],
    "zodiac_wheel": [S("back", "", [(255, 210, 80), (90, 120, 230)], 12, 0.7, 2.0, r=2.3)],
    "element_orbs": [S("orbit", "ball", [(255, 90, 50), (70, 160, 255), (110, 220, 90), (170, 120, 70)], 4, 0.7, 2.0)],
    "phoenix_wings": [S("back", "", FIRE, 14, 1.0, 3.0, r=2.4)],
    "tentacle_swirl": [S("orbit", "drop", [(120, 80, 200), (80, 160, 255)], 12, 0.5, 0.6)],
    "glow_leaves": [S("orbit", "leaf", [(150, 255, 120), (255, 230, 120)], 10, 0.5, 2.0)],
    "cloud_follow": [S("ground", "cloud", [(255, 255, 255), (225, 240, 255)], 5, 0.8, 0.2)],
    "lightning_ring": [S("ring", "", [(255, 240, 80), (180, 220, 255)], 22, 0.35, 3.0, z=(1.4,)), S("orbit", "bolt", [(255, 240, 80)], 4, 0.7, 3.0)],
    "infinity_loop": [S("orbit", "spark", RAINBOW, 12, 0.3, 3.0, z=(4.5, 5.2))],
    "pixel_coins": [S("orbit", "coin", GOLDS, 5, 0.6, 1.0), S("orbit", "heart", [(255, 60, 90)], 3, 0.5, 1.0, seed=8)],
    "candy_rain": [S("above", "candy", [(255, 120, 180), (120, 200, 255), (255, 220, 80)], 8, 0.5, 0.3)],
    "music_notes": [S("orbit", "note", [(255, 210, 80), (200, 140, 255)], 7, 0.6, 1.5)],
    "seasons": [S("orbit", "petal", [(255, 160, 200)], 3, 0.5, 0.3), S("orbit", "leaf", [(110, 210, 90), (255, 140, 40)], 4, 0.5, 0.3, seed=5),
                S("orbit", "flake", ICE, 3, 0.45, 0.8, seed=6)],
    "sakura_petals": [S("orbit", "petal", [(255, 170, 210), (255, 210, 230)], 14, 0.45, 0.4)],
    "lotus_glow": [S("ground", "flower", [(255, 150, 200), (255, 200, 230)], 6, 0.8, 1.0)],
    "falling_stars": [S("above", "star", GOLDS, 7, 0.45, 2.5), S("orbit", "spark", [(255, 255, 255)], 6, 0.3, 3.0)],
    "eclipse_ring": [S("back", "", [(255, 210, 90), (60, 40, 30)], 20, 0.6, 2.5, r=2.2)],
    "rainbow_beams": [S("ring", "", RAINBOW, 24, 0.45, 2.5, z=(2.2,))],
    "coin_rain": [S("above", "coin", GOLDS, 10, 0.5, 1.0)],
    "afterimage": [S("orbit", "cube", [(120, 200, 255), (190, 140, 255)], 8, 0.5, 1.5)],
    "paint_stars": [S("orbit", "star", RAINBOW, 8, 0.5, 1.5)],
    "sweetpotato_aura": [S("orbit", "sweetpotato", [(170, 90, 190)], 5, 1.0, 1.0), S("ring", "", [(255, 205, 60), (170, 90, 255)], 22, 0.35, 2.5, z=(0.15,))],
}


def effect(m, A, key):
    for st in STYLE[key]:
        z = st["z"]
        fx(m, A, st["layout"], st["kind"], st["cols"], n=st["n"], r=st["r"], z=z, s=st["s"], emit=st["emit"], seed=st["seed"])
