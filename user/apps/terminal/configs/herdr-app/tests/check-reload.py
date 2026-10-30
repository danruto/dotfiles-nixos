import importlib.util
import tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("reload_links", Path(__file__).resolve().parent.parent / "reload.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    source, live = root / "source", root / "live"
    for folder in [source / "mods/custom", source / "layouts", live / "mods", live / "layouts"]:
        folder.mkdir(parents=True)
    (source / "mods/custom/main.js").write_text("synthetic")
    (source / "layouts/custom.json").write_text("{}")
    mod = live / "mods/custom"
    mod.symlink_to(source / "mods/custom")
    layout = live / "layouts/custom.json"
    layout.symlink_to(source / "layouts/custom.json")
    original = mod.lstat().st_ino
    assert module.reload_links(source, live) == 2
    assert mod.lstat().st_ino != original
    assert (mod / "main.js").read_text() == "synthetic"
    assert layout.read_text() == "{}"
    original = mod.lstat().st_ino
    layout.unlink()
    layout.write_text("unmanaged")
    try:
        module.reload_links(source, live)
        raise AssertionError("An unmanaged file was accepted")
    except ValueError:
        pass
    assert mod.lstat().st_ino == original
    assert layout.read_text() == "unmanaged"
    assert not list(live.rglob(".*.reload-*"))

print("PASS: symlink reload preserves targets/content, refreshes entries, preflights ownership and leaves unmanaged files alone")
