"""Pure-function tests: address normalization, formatting, pruning, label cascade."""
from __future__ import annotations

import json
from pathlib import Path

import pytest

from .conftest import ton


# ---------- address normalization ----------

RAW = "0:CA1D9EDEEF40B3A9DBD9082F3767859547C3CE0BF641D09D58E33A3CF06FB309"
UQ = "UQDKHZ7e70CzqdvZCC83Z4WVR8POC_ZB0J1Y4zo88G-zCSRH"  # same addr, non-bounceable
EQ = "EQDKHZ7e70CzqdvZCC83Z4WVR8POC_ZB0J1Y4zo88G-zCXmC"  # same addr, bounceable


def test_norm_raw_from_raw():
    assert ton.norm_raw(RAW) == RAW


def test_norm_raw_from_uq():
    assert ton.norm_raw(UQ) == RAW


def test_norm_raw_from_eq():
    assert ton.norm_raw(EQ) == RAW


def test_norm_raw_lowercase_input():
    assert ton.norm_raw(RAW.lower()) == RAW


def test_norm_raw_bad_input():
    with pytest.raises(Exception):
        ton.norm_raw("definitely not an address")


# ---------- formatting ----------

def test_fmt_ton_zero():
    assert ton.fmt_ton(0) == "0"
    assert ton.fmt_ton(None) == "0"
    assert ton.fmt_ton("") == "0"


def test_fmt_ton_whole():
    assert ton.fmt_ton(5_000_000_000) == "5"


def test_fmt_ton_fractional():
    assert ton.fmt_ton(1_234_500_000) == "1.234"  # trailing 0 stripped


def test_fmt_ton_small():
    # 100_000_000 ns → 0.1 TON
    assert ton.fmt_ton(100_000_000) == "0.1"


def test_fmt_ts_none():
    assert ton.fmt_ts(None) == "-"
    assert ton.fmt_ts(0) == "-"


def test_fmt_ts_unix():
    # 1704067200 = 2024-01-01 00:00:00 UTC
    assert ton.fmt_ts(1_704_067_200) == "2024-01-01 00:00:00"


def test_flags_of_clean_wallet():
    assert ton.flags_of({"is_wallet": True}) == "-"


def test_flags_of_scam():
    assert ton.flags_of({"is_wallet": True, "is_scam": True}) == "scam"


def test_flags_of_memo_required():
    assert ton.flags_of({"is_wallet": True, "memo_required": True}) == "memo"


def test_flags_of_contract():
    # no is_wallet means True by default per default arg — so pass False explicitly
    assert "contract" in ton.flags_of({"is_wallet": False, "is_scam": False})


def test_flags_of_multiple():
    out = ton.flags_of({"is_wallet": False, "is_scam": True, "memo_required": True})
    assert set(out.split(",")) == {"scam", "memo", "contract"}


# ---------- pruning ----------

def test_prune_msg_drops_bytecode_and_fees():
    msg = {
        "source": {"address": "0:AAA", "is_scam": False, "is_wallet": True},
        "destination": {"address": "0:BBB", "is_scam": False, "is_wallet": True},
        "value": "1000000000",
        "fwd_fee": "123",
        "ihr_fee": "0",
        "import_fee": "0",
        "init": {"boc": "te6ccg...<big blob>"},
        "raw_body": "te6...",
        "message_content": {
            "body": "te6...",
            "decoded": {"comment": "hello"},
        },
    }
    out = ton.prune_msg(msg)
    assert out["source"] == {"address": "0:AAA"}
    assert out["destination"] == {"address": "0:BBB"}
    assert out["value"] == "1000000000"
    # Dropped technical fields
    for k in ("fwd_fee", "ihr_fee", "import_fee", "init", "raw_body", "message_content"):
        assert k not in out
    # Comment surfaced to flat field
    assert out["comment"] == "hello"


def test_prune_tx_drops_phases_and_state():
    tx = {
        "hash": "abc",
        "lt": 123,
        "utime": 1700000000,
        "success": True,
        "compute_phase": {"..."},
        "action_phase": {"..."},
        "storage_phase": {"..."},
        "credit_phase": {"..."},
        "bounce_phase": {"..."},
        "state_update": {"boc": "te6..."},
        "block": "x",
        "prev_trans_hash": "y",
        "prev_trans_lt": 1,
        "raw": "te6...",
        "total_fees": "99",
        "in_msg": {"source": {"address": "0:AAA"}, "value": "1000"},
        "out_msgs": [{"destination": {"address": "0:BBB"}, "value": "500", "fwd_fee": "1"}],
    }
    out = ton.prune_tx(tx)
    for k in ("compute_phase", "action_phase", "storage_phase", "credit_phase",
              "bounce_phase", "state_update", "block", "prev_trans_hash",
              "prev_trans_lt", "raw", "total_fees"):
        assert k not in out
    assert out["in_msg"]["source"] == {"address": "0:AAA"}
    assert "fwd_fee" not in out["out_msgs"][0]


# ---------- label cascade ----------

def test_lookup_label_prefers_local_over_tonapi(monkeypatch):
    fake_idx = {
        RAW: {"label": "binance", "category": "CEX", "organization": "binance"},
    }
    monkeypatch.setattr(ton, "_labels_index", lambda refresh=False: fake_idx)
    # Even if TONAPI gave a name, local label wins
    assert ton.lookup_label(RAW, "Binance Hot Wallet") == "binance/CEX"


def test_lookup_label_falls_back_to_tonapi_name(monkeypatch):
    monkeypatch.setattr(ton, "_labels_index", lambda refresh=False: {})
    assert ton.lookup_label(RAW, "Binance Hot Wallet") == "Binance Hot Wallet"


def test_lookup_label_empty(monkeypatch):
    monkeypatch.setattr(ton, "_labels_index", lambda refresh=False: {})
    assert ton.lookup_label(RAW, None) == ""
    assert ton.lookup_label(RAW, "") == ""
    assert ton.lookup_label(RAW, "   ") == ""


def test_lookup_label_category_only(monkeypatch):
    fake_idx = {RAW: {"label": "", "category": "CEX", "organization": ""}}
    monkeypatch.setattr(ton, "_labels_index", lambda refresh=False: fake_idx)
    assert ton.lookup_label(RAW, "x") == "CEX"


# ---------- tx_rows (row flattening) ----------

def test_tx_rows_in_and_out():
    tx = {
        "utime": 1_704_067_200,
        "lt": 42,
        "in_msg": {
            "source": {"address": "0:AAA"},
            "value": "2000000000",
            "decoded_body": {"text": "hello"},
        },
        "out_msgs": [
            {"destination": {"address": "0:BBB"}, "value": "1000000000",
             "message_content": {"decoded": {"comment": "bye"}}},
        ],
    }
    rows = list(ton.tx_rows(tx, want_in=True, want_out=True))
    assert len(rows) == 2
    # IN row
    in_row = next(r for r in rows if r[2] == "IN")
    assert in_row[3] == "0:AAA"
    assert in_row[4] == "2"
    assert in_row[5] == "hello"
    # OUT row
    out_row = next(r for r in rows if r[2] == "OUT")
    assert out_row[3] == "0:BBB"
    assert out_row[4] == "1"
    assert out_row[5] == "bye"


def test_tx_rows_skips_zero_value():
    tx = {
        "utime": 1_704_067_200, "lt": 1,
        "out_msgs": [{"destination": {"address": "0:BBB"}, "value": "0"}],
    }
    assert list(ton.tx_rows(tx, want_in=False, want_out=True)) == []


def test_tx_rows_comment_strips_newlines_and_tabs():
    tx = {
        "utime": 1_704_067_200, "lt": 1,
        "out_msgs": [
            {"destination": {"address": "0:BBB"}, "value": "1000000000",
             "decoded_body": {"text": "hel\tlo\nworld"}},
        ],
    }
    rows = list(ton.tx_rows(tx, want_in=False, want_out=True))
    assert rows[0][5] == "hel lo world"
