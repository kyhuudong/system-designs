# Recipe: exponential-backoff retry decorator
# Stdlib-only.
# Usage:
#   from retry import retry, RetryError
#
#   @retry(max_attempts=5, base_delay=0.1)
#   def fetch_or_die() -> bytes:
#       ...
#
# Exceptions outside `only=` propagate immediately. After max_attempts
# failures the last caught exception is re-raised wrapped in RetryError.
from __future__ import annotations

import random
import time
from functools import wraps
from typing import Any, Callable, Tuple, Type, TypeVar

F = TypeVar("F", bound=Callable[..., Any])


class RetryError(RuntimeError):
    """Raised when all retry attempts have been exhausted."""


def retry(
    *,
    max_attempts: int = 3,
    base_delay: float = 0.1,
    max_delay: float = 30.0,
    jitter: float = 0.1,
    only: Tuple[Type[BaseException], ...] = (Exception,),
) -> Callable[[F], F]:
    """Return a decorator that retries the wrapped function with exponential backoff.

    Args:
        max_attempts: total tries including the first. Must be >= 1.
        base_delay: seconds to wait before the second attempt. Each subsequent
            attempt doubles the delay, capped at max_delay.
        max_delay: cap on per-attempt sleep in seconds.
        jitter: max random jitter added per sleep, as a fraction of the delay
            (0.0 disables jitter).
        only: exception types to catch. Anything not matching propagates.
    """
    if max_attempts < 1:
        raise ValueError("max_attempts must be >= 1")

    def decorator(fn: F) -> F:
        @wraps(fn)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            last_exc: BaseException | None = None
            for attempt in range(max_attempts):
                try:
                    return fn(*args, **kwargs)
                except only as exc:  # noqa: B030
                    last_exc = exc
                    if attempt == max_attempts - 1:
                        break
                    delay = min(base_delay * (2 ** attempt), max_delay)
                    if jitter > 0:
                        delay += random.random() * delay * jitter
                    time.sleep(delay)
            raise RetryError(f"{fn.__name__} failed after {max_attempts} attempts") from last_exc

        return wrapper  # type: ignore[return-value]

    return decorator
