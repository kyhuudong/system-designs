"""Tests for retry recipe."""
from __future__ import annotations

import time

import pytest

from retry import RetryError, retry


def test_retry_passes_through_on_first_success() -> None:
    calls = {"n": 0}

    @retry(max_attempts=3, base_delay=0.0)
    def f() -> int:
        calls["n"] += 1
        return 42

    assert f() == 42
    assert calls["n"] == 1


def test_retry_succeeds_after_transient_failures() -> None:
    calls = {"n": 0}

    @retry(max_attempts=5, base_delay=0.0)
    def f() -> str:
        calls["n"] += 1
        if calls["n"] < 3:
            raise RuntimeError("nope")
        return "ok"

    assert f() == "ok"
    assert calls["n"] == 3


def test_retry_gives_up_after_max_attempts() -> None:
    calls = {"n": 0}

    @retry(max_attempts=3, base_delay=0.0)
    def f() -> None:
        calls["n"] += 1
        raise RuntimeError("always")

    with pytest.raises(RetryError) as exc:
        f()
    assert calls["n"] == 3
    assert isinstance(exc.value.__cause__, RuntimeError)


def test_retry_respects_only_clause() -> None:
    """retry should not catch exceptions outside `only=`."""
    calls = {"n": 0}

    @retry(max_attempts=5, base_delay=0.0, only=(ValueError,))
    def f() -> None:
        calls["n"] += 1
        raise KeyError("not retried")

    with pytest.raises(KeyError):
        f()
    assert calls["n"] == 1


def test_retry_backoff_uses_base_delay() -> None:
    """Smoke test: with base_delay=0.05 and 3 attempts, total >= ~0.05 + ~0.10."""
    calls = {"n": 0}

    @retry(max_attempts=3, base_delay=0.05, jitter=0.0)
    def f() -> None:
        calls["n"] += 1
        raise RuntimeError

    start = time.monotonic()
    with pytest.raises(RetryError):
        f()
    elapsed = time.monotonic() - start
    assert elapsed >= 0.10
