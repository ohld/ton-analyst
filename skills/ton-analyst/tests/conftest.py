"""Test scaffolding: import the `ton` script (no .py extension) as a module."""
from __future__ import annotations

import importlib.machinery
import importlib.util
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SKILL = HERE.parent
TON_SCRIPT = SKILL / "bin" / "ton"


def _load_ton_module():
    loader = importlib.machinery.SourceFileLoader("ton_cli", str(TON_SCRIPT))
    spec = importlib.util.spec_from_loader("ton_cli", loader)
    assert spec
    mod = importlib.util.module_from_spec(spec)
    sys.modules["ton_cli"] = mod
    loader.exec_module(mod)
    return mod


ton = _load_ton_module()
