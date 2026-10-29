import csv
import json
import os
import re
import shutil
import subprocess
from urllib.parse import unquote

from runtime import runtime_root


def validate_text(path):
    content = path.read_bytes()
    if (
        content.startswith(b"\xef\xbb\xbf")
        or not content.endswith(b"\n")
        or content.endswith(b"\n\n")
        or b"\r" in content
        or any(line != line.rstrip(b" \t") for line in content.splitlines())
    ):
        raise ValueError(f"Invalid plugin text formatting: {path}")
    content.decode("utf-8")


def validate_skill(directory):
    import yaml

    name = directory.name
    if not re.fullmatch(r"[a-z][a-z0-9-]{0,63}", name):
        raise ValueError(f"Invalid local skill name: {name}")
    document = directory / "SKILL.md"
    match = re.match(r"\A---\n(.*?)\n---\n\n# [^\n]+\n", document.read_text(), re.DOTALL)
    if not match:
        raise ValueError(f"Invalid skill entry format: {name}")
    metadata = yaml.safe_load(match[1])
    if (
        not isinstance(metadata, dict)
        or list(metadata) != ["name", "description"]
        or metadata["name"] != name
        or not isinstance(metadata["description"], str)
        or not metadata["description"].strip()
    ):
        raise ValueError(f"A local skill requires only name and description: {name}")

    interface = yaml.safe_load((directory / "agents/openai.yaml").read_text())
    if (
        not isinstance(interface, dict)
        or "interface" not in interface
        or interface.keys() - {"interface", "dependencies"}
        or not isinstance(interface["interface"], dict)
        or set(interface["interface"]) != {"display_name", "short_description", "default_prompt"}
        or not all(
            isinstance(value, str) and value.strip() for value in interface["interface"].values()
        )
        or not 25 <= len(interface["interface"]["short_description"]) <= 64
        or f"$sidekick:{name}" not in interface["interface"]["default_prompt"]
    ):
        raise ValueError(f"Invalid Sidekick skill interface: {name}")

    license_file = directory / "LICENSE"
    if not license_file.is_file() or not license_file.read_text().strip():
        raise ValueError(f"Missing or empty skill license: {name}")
    license_text = license_file.read_text()
    sources = re.findall(r"(?m)^Adapted from [^\n]+:\n([^\n]+)", license_text)
    if license_text.count("Adapted from ") != len(sources) or any(
        not re.fullmatch(r"https://github\.com/[\w.-]+/[\w.-]+/tree/[0-9a-f]{40}(?:/\S+)?", source)
        for source in sources
    ):
        raise ValueError(f"A skill source requires a full commit reference: {name}")


def validate_sources(module):
    records = json.loads((module / "assets/upstream.json").read_text())
    if not isinstance(records, list):
        raise TypeError("The upstream tool catalog must be an array.")
    imported = set()
    for record in records:
        if (
            not isinstance(record, dict)
            or not {"name", "repository"} <= record.keys()
            or record.keys() - {"name", "repository", "revision", "pin_reason"}
        ):
            raise ValueError("An upstream tool requires a name and repository.")
        name = record["name"]
        if (
            not isinstance(name, str)
            or not re.fullmatch(r"[a-z][a-z0-9-]{0,63}", name)
            or name in imported
        ):
            raise ValueError(f"Invalid or duplicate upstream tool: {name}")
        if not isinstance(record["repository"], str) or not re.fullmatch(
            r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", record["repository"]
        ):
            raise ValueError(f"Invalid upstream repository: {name}")
        if "revision" in record:
            if not isinstance(record["revision"], str) or not re.fullmatch(
                r"[0-9a-f]{40}", record["revision"]
            ):
                raise ValueError(f"An explicit pin requires a commit hash: {name}")
            if not isinstance(record.get("pin_reason"), str) or not record["pin_reason"].strip():
                raise ValueError(f"A compatibility pin requires a reason: {name}")
        elif "pin_reason" in record:
            raise ValueError(f"A pin reason requires an explicit revision: {name}")
        imported.add(name)

    assets = module / "assets/sidekick"
    local = set()
    for path in (assets / "skills").iterdir():
        if not path.is_dir() or not (path / "SKILL.md").is_file():
            raise ValueError(f"A local skill requires its own directory and SKILL.md: {path}")
        local.add(path.name)
    with (module / "components.tsv").open() as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
    declared = {
        row["id"] for row in rows if row["group"] == "Skills" and row["manager"] == "bundled"
    }
    tools = {
        row["id"] for row in rows if row["group"] == "Tool resources" and row["manager"] == "skill"
    }
    if "mira" not in local or local != declared or imported != tools or not imported <= local:
        raise ValueError("Local skills, upstream tools and component declarations differ.")
    for name in sorted(local):
        validate_skill(assets / "skills" / name)
    for path in (module / "assets").rglob("*"):
        if path.is_file() and (path.suffix in {".md", ".yaml", ".json"} or path.name == "LICENSE"):
            validate_text(path)
    validate_package(assets, upstream_tools=imported)
    manifest = json.loads((assets / "plugin.json").read_text())
    if manifest["name"] != "sidekick" or not re.fullmatch(
        r"[0-9]+\.[0-9]+\.[0-9]+", manifest["version"]
    ):
        raise ValueError("Invalid Sidekick plugin identity or version.")
    return records


def resolve_npm_package(name, packages):
    if not re.fullmatch(r"(?:@[a-z0-9._-]+/)?[a-z0-9._-]+", name):
        raise ValueError(f"Invalid npm package name: {name}")
    if name not in packages:
        result = subprocess.run(
            ["pnpm", "view", name, "version", "engines", "bin", "--json"],
            check=True,
            capture_output=True,
            text=True,
        )
        packages[name] = json.loads(result.stdout) | {"name": name}
        print(f"Resolved npm package: {name}@{packages[name]['version']}", flush=True)
    return packages[name]


def install_upstream(repository, reference, records, project):
    if reference == "HEAD":
        result = subprocess.run(
            ["git", "ls-remote", f"https://github.com/{repository}.git", "HEAD"],
            check=True,
            capture_output=True,
            text=True,
        )
        rows = result.stdout.splitlines()
        if len(rows) != 1 or not re.fullmatch(r"[0-9a-f]{40}\s+HEAD", rows[0]):
            raise ValueError(f"Could not resolve the upstream default branch: {repository}")
        reference = rows[0].split()[0]
    names = [record["name"] for record in records]
    subprocess.run(
        [
            "pnpx",
            "skills@latest",
            "add",
            f"https://github.com/{repository}/tree/{reference}",
            "--agent",
            "codex",
            "--yes",
            "--copy",
            "--json",
            "--skill",
            *names,
        ],
        cwd=project,
        env=os.environ | {"DISABLE_TELEMETRY": "1", "TMPDIR": str(project)},
        check=True,
        capture_output=True,
        text=True,
    )
    lock = json.loads((project / "skills-lock.json").read_text())
    for name in names:
        entry = lock["skills"].get(name, {})
        if entry.get("ref") != reference or entry.get("source") != repository:
            raise ValueError(f"The skills CLI did not record the requested source: {name}")
    print(
        f"Imported tool resources: {', '.join(names)} ({repository}@{reference[:12]})",
        flush=True,
    )


def resolve_runtimes(destination):
    packages = {}
    runtimes = {"agent-browser": resolve_npm_package("agent-browser", packages)}
    path = destination / "mcp.json"
    configuration = json.loads(path.read_text())
    for identifier, server in configuration["mcpServers"].items():
        if server.get("command") != "npx":
            raise ValueError(f"Unsupported MCP runtime declaration: {identifier}")
        metadata = resolve_npm_package(server["args"][-1].removesuffix("@latest"), packages)
        binaries = metadata["bin"]
        if not isinstance(binaries, dict) or len(binaries) != 1:
            raise ValueError(f"An MCP runtime requires one executable: {identifier}")
        server["command"] = str(
            runtime_root() / identifier / "node_modules/.bin" / next(iter(binaries))
        )
        server["args"] = []
        runtimes[identifier] = metadata
    path.write_text(json.dumps(configuration, indent=2) + "\n")
    (destination / "runtime-packages.json").write_text(json.dumps(runtimes, indent=2) + "\n")


def validate_references(destination, *, upstream_tools=()):
    for document in (destination / "skills").rglob("*.md"):
        for target in re.findall(r"\]\(([^\s)]+)(?:\s+[^)]*)?\)", document.read_text()):
            if ":" in target or target.startswith("#"):
                continue
            path = unquote(target.split("#", 1)[0])
            reference = (document.parent / path).resolve()
            if not reference.is_relative_to(destination.resolve()):
                raise ValueError(f"A skill reference escapes the plugin: {document}: {target}")
            if any(
                reference.is_relative_to((destination / "vendor" / name).resolve())
                for name in upstream_tools
            ):
                continue
            if path and not reference.exists():
                raise ValueError(f"Missing skill reference: {document}: {target}")


def validate_package(destination, *, upstream_tools=()):
    validate_references(destination, upstream_tools=upstream_tools)
    for path in destination.rglob("*"):
        if path.is_symlink() and (
            not path.exists() or not path.resolve().is_relative_to(destination.resolve())
        ):
            raise ValueError(f"A packaged symlink escapes the plugin or has no target: {path}")


def build_plugin(module, destination, work):
    records = validate_sources(module)
    shutil.copytree(module / "assets/sidekick", destination, symlinks=True)
    project = work / "upstream"
    project.mkdir()
    vendor = destination / "vendor"
    vendor.mkdir()
    repositories = {}
    for record in records:
        repositories.setdefault((record["repository"], record.get("revision", "HEAD")), []).append(
            record
        )
    for (repository, reference), group in repositories.items():
        install_upstream(repository, reference, group, project)
        for record in group:
            source = project / ".agents/skills" / record["name"]
            if not (source / "SKILL.md").is_file() or not (source / "LICENSE").is_file():
                raise ValueError(f"Missing upstream tool instructions or license: {record['name']}")
            shutil.copytree(
                source,
                vendor / record["name"],
                symlinks=True,
                ignore=shutil.ignore_patterns(".git", ".venv", "node_modules", "__pycache__"),
            )
    shutil.copy2(project / "skills-lock.json", destination / "skills-lock.json")
    resolve_runtimes(destination)
    validate_package(destination)
    print(
        f"Assembled Sidekick: {len(list((destination / 'skills').glob('*/SKILL.md')))} local skills, {len(records)} upstream tool bundles."
    )
