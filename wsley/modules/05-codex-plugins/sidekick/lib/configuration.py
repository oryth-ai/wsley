import os
import tempfile
from collections.abc import MutableMapping
from pathlib import Path

INSTRUCTION = (
    "Read and follow sidekick:mira for project work. "
    "After context compaction or a handoff, reread it and resume unfinished work."
)
BLOCK_START = "<wsley-sidekick>"
BLOCK_END = "</wsley-sidekick>"
INSTRUCTION_BLOCK = f"{BLOCK_START}\n{INSTRUCTION}\n{BLOCK_END}"
AGENT_THREAD_LIMIT_KEY = "max_concurrent_threads_per_session"
AGENT_THREAD_LIMIT = 20


def update_configuration(original):
    import tomlkit

    document = tomlkit.parse(original)
    current = document.get("developer_instructions", "")
    if not isinstance(current, str):
        raise TypeError("Codex developer_instructions must be a string.")

    starts = current.count(BLOCK_START)
    ends = current.count(BLOCK_END)
    if starts == 0 and ends == 0:
        separator = ""
        if current and not current.endswith("\n\n"):
            separator = "\n" if current.endswith("\n") else "\n\n"
        replacement = current + separator + INSTRUCTION_BLOCK
    elif starts == 1 and ends == 1:
        start = current.index(BLOCK_START)
        end = current.index(BLOCK_END)
        if end < start:
            raise ValueError("Sidekick instruction markers are out of order.")
        replacement = current[:start] + INSTRUCTION_BLOCK + current[end + len(BLOCK_END) :]
    else:
        raise ValueError("Sidekick requires one complete instruction block.")

    agents = document.setdefault("agents", tomlkit.table())
    if not isinstance(agents, MutableMapping):
        raise TypeError("Codex agents must be a table.")
    limit = agents.get(AGENT_THREAD_LIMIT_KEY)
    if limit is not None and (not isinstance(limit, int) or isinstance(limit, bool) or limit < 1):
        raise ValueError(f"Codex agents.{AGENT_THREAD_LIMIT_KEY} must be a positive integer.")
    update_limit = limit != AGENT_THREAD_LIMIT
    if replacement == current and not update_limit:
        return original
    if replacement != current:
        document["developer_instructions"] = tomlkit.string(replacement)
    if update_limit:
        agents[AGENT_THREAD_LIMIT_KEY] = AGENT_THREAD_LIMIT
    return tomlkit.dumps(document)


def write_configuration(configuration, replacement, *, backup, replace_symlink=False):
    configuration = Path(configuration)
    original = configuration.read_text() if configuration.exists() else ""
    if replacement == original and not (replace_symlink and configuration.is_symlink()):
        return False
    configuration.parent.mkdir(parents=True, exist_ok=True)
    descriptor, name = tempfile.mkstemp(prefix=".wsley-sidekick-", dir=configuration.parent)
    os.close(descriptor)
    temporary = Path(name)
    try:
        temporary.write_text(replacement)
        temporary.chmod(configuration.stat().st_mode & 0o777 if configuration.exists() else 0o600)
        backup(configuration)
        temporary.replace(configuration)
    finally:
        temporary.unlink(missing_ok=True)
    return True


def configure_codex(configuration, *, backup):
    configuration = Path(configuration)
    original = configuration.read_text() if configuration.exists() else ""
    write_configuration(configuration, update_configuration(original), backup=backup)
