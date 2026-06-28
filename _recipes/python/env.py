# Recipe: typed env-var loader
# Stdlib-only.
# Usage:
#   from env import get_str, get_int, get_bool, require, MissingEnvError
#
#   port = get_int("PORT", default=8080)
#   debug = get_bool("DEBUG", default=False)
#   db_url = require("DATABASE_URL")  # raises MissingEnvError if absent
from __future__ import annotations

import os
from typing import overload


class MissingEnvError(RuntimeError):
    """Raised by `require` when a required env var is not set."""


_TRUE = {"1", "true", "yes", "on"}
_FALSE = {"0", "false", "no", "off", ""}


@overload
def get_str(name: str) -> str | None: ...
@overload
def get_str(name: str, *, default: str) -> str: ...
def get_str(name: str, *, default: str | None = None) -> str | None:
    """Return the env var as a string, or `default` if unset."""
    value = os.environ.get(name)
    if value is None:
        return default
    return value


@overload
def get_int(name: str) -> int | None: ...
@overload
def get_int(name: str, *, default: int) -> int: ...
def get_int(name: str, *, default: int | None = None) -> int | None:
    """Return the env var parsed as int, or `default` if unset.

    Raises ValueError if the value is set but not parseable.
    """
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError as exc:
        raise ValueError(f"env {name}={raw!r} is not a valid integer") from exc


@overload
def get_bool(name: str) -> bool | None: ...
@overload
def get_bool(name: str, *, default: bool) -> bool: ...
def get_bool(name: str, *, default: bool | None = None) -> bool | None:
    """Return the env var parsed as bool, or `default` if unset.

    Accepts (case-insensitive): 1/0, true/false, yes/no, on/off, "".
    Raises ValueError on anything else.
    """
    raw = os.environ.get(name)
    if raw is None:
        return default
    low = raw.lower()
    if low in _TRUE:
        return True
    if low in _FALSE:
        return False
    raise ValueError(f"env {name}={raw!r} is not a valid boolean")


def require(name: str) -> str:
    """Return the env var, or raise MissingEnvError if not set or empty."""
    value = os.environ.get(name)
    if value is None or value == "":
        raise MissingEnvError(f"required env var {name} is not set")
    return value
