#!/usr/bin/env python3

import argparse
import filecmp
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from configuration import configure_codex, update_configuration, write_configuration
from package import build_plugin, validate_sources
from runtime import check_runtimes, install_runtimes


def run(arguments, **options):
    return subprocess.run(arguments, check=True, text=True, **options)


def codex(*arguments):
    return json.loads(run(["codex", "plugin", *arguments, "--json"], capture_output=True).stdout)


def installed_plugin():
    return next(
        (item for item in codex("list")["installed"] if item["pluginId"] == "sidekick@wsley"),
        None,
    )


def backup(module, target):
    run(
        [
            "bash",
            "-ec",
            'source "$1"; backup_file "$2"',
            "bash",
            str(module.parents[2] / "lib/backup.sh"),
            str(target),
        ]
    )


def remove_path(path):
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.exists():
        shutil.rmtree(path)


def copy_path(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    run(["cp", "-a", "--", str(source), str(target)])


def same_tree(source, target):
    if source.is_symlink() or target.is_symlink():
        return (
            source.is_symlink() and target.is_symlink() and source.readlink() == target.readlink()
        )
    if not source.exists() or not target.exists():
        return False
    if source.stat().st_mode != target.stat().st_mode:
        return False
    if source.is_file() and target.is_file():
        return filecmp.cmp(source, target, shallow=False)
    if source.is_dir() and target.is_dir():
        names = {path.name for path in source.iterdir()}
        return names == {path.name for path in target.iterdir()} and all(
            same_tree(source / name, target / name) for name in names
        )
    return False


def apply_plugin(module, upgrading):
    current = installed_plugin()
    if upgrading and current is None:
        print("Skipped Sidekick: not installed; use wsley install.")
        return
    data = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    codex_home = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex")
    if not data.is_absolute() or not codex_home.is_absolute():
        raise ValueError("XDG_DATA_HOME and CODEX_HOME must be absolute paths.")
    root = data / "sidekick"
    root.mkdir(parents=True, exist_ok=True)
    source = root / "plugin"
    catalog = root / ".agents/plugins/marketplace.json"
    configuration = codex_home / "config.toml"
    original = configuration.read_text() if configuration.exists() else ""
    update_configuration(original)
    cache = codex_home / "plugins/cache/wsley/sidekick"
    if current is not None and Path(current["source"]["path"]).resolve() != source.resolve():
        raise ValueError(
            "Sidekick is registered from another source; existing registration was preserved."
        )
    marketplace = next(
        (item for item in codex("marketplace", "list")["marketplaces"] if item["name"] == "wsley"),
        None,
    )
    if marketplace is not None and Path(marketplace["root"]).resolve() != root.resolve():
        raise ValueError("The Wsley marketplace name is already registered from another source.")
    if current is not None and not upgrading and current["enabled"] and marketplace is not None:
        install_runtimes(source, False, lambda target: backup(module, target))
        configure_codex(configuration, backup=lambda target: backup(module, target))
        print("Skipped Sidekick plugin files: already installed.")
        return
    with tempfile.TemporaryDirectory(prefix=".sidekick-", dir=root) as temporary:
        stage = Path(temporary)
        package = stage / "package"
        if current is None or upgrading:
            build_plugin(module, package, stage)
        replace_package = package.exists() and not same_tree(package, source)
        install_runtimes(
            package if package.exists() else source,
            upgrading,
            lambda target: backup(module, target),
        )
        listing = {
            "name": "wsley",
            "interface": {"displayName": "Wsley"},
            "plugins": [
                {
                    "name": "sidekick",
                    "source": {"source": "local", "path": "./plugin"},
                    "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},
                    "category": "Developer Tools",
                }
            ],
        }
        content = json.dumps(listing, indent=2) + "\n"
        replace_catalog = not catalog.exists() or catalog.read_text() != content
        refresh = current is None or not current["enabled"] or replace_package
        if current is not None and not refresh:
            refresh = not same_tree(source, cache / current["version"])
        commands = []
        if marketplace is None:
            commands.append(("marketplace", "add", str(root)))
        if refresh:
            commands.append(("add", "sidekick@wsley"))
        targets = [configuration]
        if replace_package:
            targets.append(source)
        if replace_catalog:
            targets.append(catalog)
        if refresh:
            targets.append(cache)
        previous = []
        for index, target in enumerate(targets):
            saved = stage / f"previous-{index}"
            exists = target.exists() or target.is_symlink()
            if exists:
                copy_path(target, saved)
            previous.append((target, saved, exists))
        last_configuration = None

        def backup_configuration(target):
            nonlocal last_configuration
            state = None
            if target.is_symlink():
                state = ("link", target.readlink())
            elif target.is_file():
                state = ("file", target.stat().st_mode, target.read_bytes())
            if state != last_configuration:
                backup(module, target)
                last_configuration = state

        started = False
        try:
            if replace_package:
                backup(module, source)
                started = True
                remove_path(source)
                package.replace(source)
            if replace_catalog:
                started = True
                write_configuration(catalog, content, backup=lambda target: backup(module, target))
            for arguments in commands:
                started = True
                detached = write_configuration(
                    configuration,
                    configuration.read_text() if configuration.exists() else "",
                    backup=backup_configuration,
                    replace_symlink=True,
                )
                if not detached:
                    backup_configuration(configuration)
                if arguments[0] == "add":
                    backup(module, cache)
                    remove_path(cache)
                codex(*arguments)
            if current is not None and not upgrading:
                for target, saved, existed in previous:
                    if target == cache and existed:
                        remove_path(cache)
                        copy_path(saved, cache)
            started = True
            configure_codex(configuration, backup=backup_configuration)
            enabled = installed_plugin()
            if enabled is None or not enabled["enabled"]:
                raise ValueError("Codex did not enable Sidekick.")
        except BaseException:
            if started:
                try:
                    for target, saved, existed in reversed(previous):
                        remove_path(target)
                        if existed:
                            copy_path(saved, target)
                except (OSError, subprocess.CalledProcessError) as error:
                    recovery = root / ("sidekick-recovery-" + stage.name)
                    stage.rename(recovery)
                    raise OSError(f"Recovery files retained: {recovery}") from error
            raise
    print(f"Sidekick installed and enabled: {source}")


def status(module):
    current = installed_plugin()
    if current is None:
        print("Sidekick: not-installed")
        return
    print(
        f"Sidekick: installed, {'enabled' if current['enabled'] else 'disabled'}, version {current['version']}"
    )
    print(f"Plugin source: {current['source']['path']}")
    sources = Path(current["source"]["path"]) / "skills-lock.json"
    print(f"Upstream tool sources: {sources if sources.is_file() else 'missing'}")
    configuration = Path(os.environ.get("CODEX_HOME") or Path.home() / ".codex") / "config.toml"
    original = configuration.read_text() if configuration.exists() else ""
    configured = update_configuration(original) == original
    print(f"Sidekick Codex configuration: {'configured' if configured else 'missing or outdated'}")
    check_runtimes(Path(current["source"]["path"]), quick=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "action",
        choices=("validate", "build", "installed", "install", "upgrade", "status"),
    )
    parser.add_argument("module", type=Path)
    parser.add_argument("destination", type=Path, nargs="?")
    arguments = parser.parse_args()
    module = arguments.module.resolve()
    if arguments.action == "validate":
        validate_sources(module)
        print("Sidekick plugin sources validated.")
    elif arguments.action == "build":
        if arguments.destination is None:
            parser.error("build requires a destination")
        with tempfile.TemporaryDirectory(
            prefix="sidekick-upstream-", dir=arguments.destination.resolve().parent
        ) as work:
            build_plugin(module, arguments.destination.resolve(), Path(work))
    elif arguments.action == "installed":
        return 0 if installed_plugin() is not None else 1
    elif arguments.action == "status":
        status(module)
    else:
        apply_plugin(module, arguments.action == "upgrade")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, TypeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Sidekick: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            for output in (error.stdout, error.stderr):
                if output:
                    print(output, file=sys.stderr)
        sys.exit(2)
