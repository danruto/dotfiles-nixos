import os
from pathlib import Path


def reload_links(source, live):
    assets = sorted(path.relative_to(source) for path in (source / "mods").iterdir() if path.is_dir())
    assets += sorted(path.relative_to(source) for path in (source / "layouts").iterdir() if path.suffix in {".json", ".svg"})
    for asset in assets:
        target = live / asset
        if not target.is_symlink() or target.resolve() != (source / asset).resolve():
            raise ValueError(f"Expected an owned config symlink: {target}")
    for asset in assets:
        target = live / asset
        temporary = target.with_name(f".{target.name}.reload-{os.getpid()}")
        try:
            temporary.symlink_to(os.readlink(target))
            os.replace(temporary, target)
        finally:
            if temporary.is_symlink():
                temporary.unlink()
    return len(assets)


if __name__ == "__main__":
    source = Path(__file__).resolve().parent
    live = Path(os.environ.get("HERDR_APP_HOME", Path.home() / ".config/herdr-app"))
    print(f"Refreshed {reload_links(source, live)} owned Herdr config links")
