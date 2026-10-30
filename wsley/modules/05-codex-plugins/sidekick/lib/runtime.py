import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from configuration import write_configuration


def runtime_root():
    data = Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")
    if not data.is_absolute():
        raise ValueError("XDG_DATA_HOME must be an absolute path.")
    return data / "sidekick/runtimes"


def validate_runtime_directory(directory):
    if directory.is_symlink() or (directory.exists() and not directory.is_dir()):
        raise ValueError(f"A managed runtime must be a directory, not a link or file: {directory}")


def runtime_package_matches(directory, metadata):
    installed = directory / "node_modules" / metadata["name"] / "package.json"
    if not installed.is_file():
        return False
    try:
        current = json.loads(installed.read_text())
    except (OSError, ValueError):
        return False
    return (
        isinstance(current, dict)
        and current.get("version") == metadata["version"]
        and all(
            os.access(directory / "node_modules/.bin" / binary, os.X_OK)
            for binary in metadata["bin"]
        )
    )


def presentation_interpreter(directory):
    environment = directory / ".venv"
    interpreter = environment / "bin/python"
    if environment.is_dir() and not environment.is_symlink():
        try:
            result = subprocess.run(
                [
                    str(interpreter),
                    "-c",
                    "import pathlib, sys; sys.exit(0 if sys.version_info[:2] == (3, 12) and pathlib.Path(sys.prefix).resolve() == pathlib.Path(sys.argv[1]).resolve() else 1)",
                    str(environment),
                ],
                capture_output=True,
                check=False,
                timeout=10,
            )
            if result.returncode == 0:
                return interpreter
        except (OSError, subprocess.TimeoutExpired):
            pass
    return None


def create_presentation_environment(directory):
    environment = directory / ".venv"
    if environment.is_symlink() or (environment.exists() and not environment.is_dir()):
        environment.unlink()
    elif environment.exists():
        shutil.rmtree(environment)
    subprocess.run(["uv", "venv", "--python", "3.12", str(environment)], check=True)
    return environment / "bin/python"


def install_runtimes(plugin, upgrading, backup):
    root = runtime_root()
    if root.is_symlink() or (root.exists() and not root.is_dir()):
        raise ValueError(f"The runtime root must be a directory, not a link or file: {root}")
    chromium = root / "chromium"
    if chromium.exists() and not chromium.is_symlink():
        raise ValueError(f"The managed Chromium path must be a symlink: {chromium}")
    packages = json.loads((plugin / "runtime-packages.json").read_text())
    for name, metadata in packages.items():
        directory = root / name
        validate_runtime_directory(directory)
        if runtime_package_matches(directory, metadata):
            print(f"Skipped {name}: {metadata['version']} is already installed.")
            continue
        backup(directory)
        directory.mkdir(parents=True, exist_ok=True)
        arguments = [
            "pnpm",
            "--dir",
            str(directory),
            "add",
            "--config.engine-strict=true",
            "--save-exact",
            metadata["name"] + "@" + metadata["version"],
        ]
        if name == "agent-browser":
            arguments.append("--allow-build=agent-browser")
        subprocess.run(arguments, check=True)

    browser = root / "agent-browser/node_modules/.bin/agent-browser"
    subprocess.run([str(browser), "install", "--with-deps"], check=True)

    directory = root / "ppt-master"
    validate_runtime_directory(directory)
    interpreter = presentation_interpreter(directory)
    rebuilt = interpreter is None
    if rebuilt:
        backup(directory)
        directory.mkdir(parents=True, exist_ok=True)
        interpreter = create_presentation_environment(directory)
    requirements = plugin / "vendor/ppt-master/requirements.txt"
    arguments = [
        "uv",
        "pip",
        "install",
        "--python",
        str(interpreter),
        "--requirement",
        str(requirements),
    ]
    if upgrading:
        arguments.append("--upgrade")
    changes = True
    if not rebuilt:
        print("Resolving presentation dependencies...", flush=True)
        result = subprocess.run(
            [*arguments, "--dry-run", "--output-format", "json"],
            check=True,
            capture_output=True,
            text=True,
        )
        plan = json.loads(result.stdout)
        if not isinstance(plan, dict) or not isinstance(plan.get("changes"), list):
            raise ValueError("The uv installation plan must contain a changes array.")
        changes = bool(plan["changes"])
    if changes:
        if not rebuilt:
            backup(directory)
        subprocess.run(arguments, check=True)
    else:
        print("Skipped presentation dependencies: the environment already satisfies the plan.")
    digest = hashlib.sha256(requirements.read_bytes()).hexdigest()
    write_configuration(
        directory / "requirements.sha256",
        digest + "\n",
        backup=(lambda target: None) if rebuilt or changes else backup,
    )

    result = check_runtimes(plugin)
    if not result["ready"]:
        raise ValueError(
            "Sidekick environment validation failed; rerun wsley install sidekick after fixing the reported errors."
        )
    if not chromium.is_symlink() or chromium.resolve() != result["chromium"].resolve():
        with tempfile.TemporaryDirectory(prefix=".chromium-", dir=root) as temporary:
            link = Path(temporary) / "chromium"
            link.symlink_to(result["chromium"])
            backup(chromium)
            link.replace(chromium)
    print(f"Chromium executable: {chromium}")


def chromium_path(report):
    for check in report.get("checks", []):
        if check.get("id") == "chrome.installed" and check.get("status") == "pass":
            path = Path(check.get("message", "").rpartition(" at ")[2])
            if path.is_absolute() and os.access(path, os.X_OK):
                return path
    return None


def check_runtimes(plugin, quick=False):
    root = runtime_root()
    manifest = plugin / "runtime-packages.json"
    if not manifest.is_file():
        print("Sidekick environments: missing runtime package manifest.")
        return {"ready": False, "chromium": None}
    ready = True
    chromium = None
    packages = json.loads(manifest.read_text())
    for name, metadata in packages.items():
        matches = runtime_package_matches(root / name, metadata)
        print(
            f"{name}: {'installed' if matches else 'missing or outdated'} ({metadata['version']})"
        )
        ready = ready and matches

    browser = root / "agent-browser/node_modules/.bin/agent-browser"
    interpreter = root / "ppt-master/.venv/bin/python"
    checks = [
        ("Browser instructions", [str(browser), "skills", "get", "core"]),
        (
            "Chromium",
            [str(browser), "doctor", "--offline", "--json"] + (["--quick"] if quick else []),
        ),
        (
            "Presentation imports",
            [
                str(interpreter),
                "-c",
                "import pathlib, sys, pptx, PIL, yaml, pathops, uharfbuzz; assert sys.version_info[:2] == (3, 12); assert pathlib.Path(sys.prefix).resolve() == pathlib.Path(sys.argv[1]).resolve()",
                str(interpreter.parent.parent),
            ],
        ),
        (
            "Presentation dependencies",
            ["uv", "pip", "check", "--python", str(interpreter)],
        ),
        ("LibreOffice", ["libreoffice", "--headless", "--version"]),
        ("Pandoc", ["pandoc", "--version"]),
        ("FFmpeg", ["ffmpeg", "-version"]),
        ("FFprobe", ["ffprobe", "-version"]),
        ("Fonts", ["fc-match", "sans-serif:lang=zh-cn"]),
    ]
    for label, arguments in checks:
        try:
            result = subprocess.run(
                arguments,
                capture_output=True,
                text=True,
                check=False,
                timeout=30 if quick else 60,
            )
            passed = result.returncode == 0
            detail = (result.stderr or result.stdout).strip() if not passed else ""
            if label == "Chromium" and passed:
                chromium = chromium_path(json.loads(result.stdout))
                passed = chromium is not None
                if not passed:
                    detail = "The browser CLI did not report an executable Chromium path."
        except (OSError, ValueError, subprocess.TimeoutExpired) as error:
            passed, detail = False, str(error)
        print(f"{label}: {'ready' if passed else 'failed'}")
        if detail:
            print(detail)
        ready = ready and passed

    requirements = plugin / "vendor/ppt-master/requirements.txt"
    stamp = root / "ppt-master/requirements.sha256"
    synchronized = (
        requirements.is_file()
        and stamp.is_file()
        and stamp.read_text().strip() == hashlib.sha256(requirements.read_bytes()).hexdigest()
    )
    print(f"Presentation requirements: {'synchronized' if synchronized else 'not synchronized'}")
    if quick:
        link = root / "chromium"
        bound = chromium is not None and link.is_symlink() and link.resolve() == chromium.resolve()
        print(f"Chromium binding: {'ready' if bound else 'missing or outdated'}")
        ready = ready and bound
    return {"ready": ready and synchronized, "chromium": chromium}
