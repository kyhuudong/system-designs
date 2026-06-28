"""Tests for env recipe."""
from __future__ import annotations

import os

import pytest

from env import MissingEnvError, get_bool, get_int, get_str, require


def setup_function() -> None:
    for k in list(os.environ):
        if k.startswith("TEST_RECIPE_"):
            del os.environ[k]


def test_get_str_returns_value_when_set() -> None:
    os.environ["TEST_RECIPE_FOO"] = "bar"
    assert get_str("TEST_RECIPE_FOO") == "bar"


def test_get_str_returns_default_when_missing() -> None:
    assert get_str("TEST_RECIPE_MISSING", default="fallback") == "fallback"


def test_get_str_returns_none_when_missing_no_default() -> None:
    assert get_str("TEST_RECIPE_MISSING") is None


def test_get_int_parses() -> None:
    os.environ["TEST_RECIPE_PORT"] = "8080"
    assert get_int("TEST_RECIPE_PORT") == 8080


def test_get_int_rejects_non_numeric() -> None:
    os.environ["TEST_RECIPE_PORT"] = "abc"
    with pytest.raises(ValueError):
        get_int("TEST_RECIPE_PORT")


def test_get_bool_truthy_values() -> None:
    for truthy in ("1", "true", "TRUE", "yes", "on"):
        os.environ["TEST_RECIPE_FLAG"] = truthy
        assert get_bool("TEST_RECIPE_FLAG") is True


def test_get_bool_falsy_values() -> None:
    for falsy in ("0", "false", "FALSE", "no", "off", ""):
        os.environ["TEST_RECIPE_FLAG"] = falsy
        assert get_bool("TEST_RECIPE_FLAG") is False


def test_get_bool_unknown_raises() -> None:
    os.environ["TEST_RECIPE_FLAG"] = "maybe"
    with pytest.raises(ValueError):
        get_bool("TEST_RECIPE_FLAG")


def test_require_raises_when_missing() -> None:
    with pytest.raises(MissingEnvError):
        require("TEST_RECIPE_MUST_HAVE")


def test_require_returns_value() -> None:
    os.environ["TEST_RECIPE_MUST_HAVE"] = "ok"
    assert require("TEST_RECIPE_MUST_HAVE") == "ok"
