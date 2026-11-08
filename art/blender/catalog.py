"""All cat designs: the samples and Basic tier in blockcat.py, then one module per tier (each adds its designs to
blockcat.DESIGNS). Import this, then call blockcat.build(name)."""
import importlib

import blockcat

for _mod in ("cats_rare", "cats_epic", "cats_legendary", "cats_mythical", "cats_secret"):
    try:
        importlib.import_module(_mod)
    except ModuleNotFoundError as e:  # a tier not written yet
        if e.name != _mod:
            raise

DESIGNS = blockcat.DESIGNS
build = blockcat.build
