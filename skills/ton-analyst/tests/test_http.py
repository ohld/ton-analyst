"""HTTP-level tests using httpx.MockTransport — no network access."""
from __future__ import annotations

import asyncio
import json
import sys
from io import StringIO

import httpx
import pytest

from .conftest import ton


def _mock_client(handler):
    return httpx.AsyncClient(base_url="https://tonapi.io", transport=httpx.MockTransport(handler))


# ---------- tonapi() helper ----------

def test_tonapi_happy_path():
    def handler(req: httpx.Request) -> httpx.Response:
        assert req.url.path == "/v2/accounts/foo"
        return httpx.Response(200, json={"ok": True})

    async def go():
        async with _mock_client(handler) as c:
            return await ton.tonapi(c, "/v2/accounts/foo")

    assert asyncio.run(go()) == {"ok": True}


def test_tonapi_404_exits_3():
    def handler(req):
        return httpx.Response(404, json={"error": "not found"})

    async def go():
        async with _mock_client(handler) as c:
            await ton.tonapi(c, "/v2/accounts/missing")

    with pytest.raises(SystemExit) as exc:
        asyncio.run(go())
    assert exc.value.code == 3


def test_tonapi_429_exits_4_with_hint(capsys):
    def handler(req):
        return httpx.Response(429, text="slow down")

    async def go():
        async with _mock_client(handler) as c:
            await ton.tonapi(c, "/v2/accounts/foo")

    with pytest.raises(SystemExit) as exc:
        asyncio.run(go())
    assert exc.value.code == 4
    err = capsys.readouterr().err
    assert "rate limited" in err
    assert "TONAPI_API_KEY" in err


def test_tonapi_500_exits_4():
    def handler(req):
        return httpx.Response(500, text="boom")

    async def go():
        async with _mock_client(handler) as c:
            await ton.tonapi(c, "/v2/accounts/foo")

    with pytest.raises(SystemExit) as exc:
        asyncio.run(go())
    assert exc.value.code == 4


def test_tonapi_sends_bearer_when_key_set(monkeypatch):
    captured = {}

    def handler(req: httpx.Request) -> httpx.Response:
        captured["auth"] = req.headers.get("authorization")
        return httpx.Response(200, json={})

    monkeypatch.setattr(ton, "TONAPI_KEY", "sekret")

    async def go():
        async with _mock_client(handler) as c:
            await ton.tonapi(c, "/v2/accounts/foo")

    asyncio.run(go())
    assert captured["auth"] == "Bearer sekret"


# ---------- cmd_acc end-to-end ----------

RAW = "0:CA1D9EDEEF40B3A9DBD9082F3767859547C3CE0BF641D09D58E33A3CF06FB309"


def test_cmd_acc_tsv(monkeypatch, capsys):
    monkeypatch.setattr(ton, "_labels_index", lambda refresh=False: {})
    responses = {
        f"/v2/accounts/{RAW}": {
            "address": RAW,
            "name": "Binance Hot Wallet",
            "status": "active",
            "balance": "3511508124000000",
            "is_wallet": True,
            "is_scam": False,
        },
        f"/v2/accounts/{RAW}/jettons": {"balances": []},
    }

    def handler(req):
        return httpx.Response(200, json=responses[req.url.path])

    class NS:
        addr = RAW
        jettons = 3
        json = False

    async def go():
        async with _mock_client(handler) as c:
            await ton.cmd_acc(c, NS())

    asyncio.run(go())
    out = capsys.readouterr().out.strip()
    cols = out.split("\t")
    assert cols[0] == RAW
    assert cols[1] == "Binance Hot Wallet"
    assert cols[2] == "active"
    assert cols[3] == "3511508.124"
    assert cols[4] == "-"  # flags
    assert cols[5] == "-"  # no jettons


# ---------- cmd_tx TSV filters ----------

def _tx_doc():
    return {
        "transactions": [
            {
                "lt": 100, "utime": 1_704_067_200,
                "in_msg": None,
                "out_msgs": [
                    {"destination": {"address": "0:AAA"}, "value": "2000000000",
                     "decoded_body": {"text": "hi"}}
                ],
            },
            {
                "lt": 90, "utime": 1_704_067_100,
                "in_msg": {"source": {"address": "0:BBB"}, "value": "500000000"},
                "out_msgs": [],
            },
            {
                "lt": 80, "utime": 1_704_067_000,
                "in_msg": None,
                "out_msgs": [
                    {"destination": {"address": DEST_RAW}, "value": "10000000000",
                     "decoded_body": {"text": ""}},
                ],
            },
        ]
    }


DEST_RAW = "0:CA1D9EDEEF40B3A9DBD9082F3767859547C3CE0BF641D09D58E33A3CF06FB309"


def _paginating_handler(doc):
    """Return txs once, then empty on any before_lt probe — prevents the CLI's
    pagination loop from fetching the same page repeatedly in tests."""
    def handler(req):
        if req.url.params.get("before_lt"):
            return httpx.Response(200, json={"transactions": []})
        return httpx.Response(200, json=doc)
    return handler


def test_cmd_tx_tsv_default(capsys):
    handler = _paginating_handler(_tx_doc())

    class NS:
        addr = RAW
        in_ = False
        out = False
        min_value = 0
        since = None
        before = None
        dest = None
        limit = 10
        before_lt = None
        json = False

    async def go():
        async with _mock_client(handler) as c:
            await ton.cmd_tx(c, NS())

    asyncio.run(go())
    captured = capsys.readouterr()
    rows = [r for r in captured.out.strip().splitlines() if r]
    # 2 OUTs + 1 IN = 3 rows
    assert len(rows) == 3
    # Footer goes to stderr
    assert "next page" in captured.err


def test_cmd_tx_out_only_min_value(capsys):
    handler = _paginating_handler(_tx_doc())

    class NS:
        addr = RAW
        in_ = False
        out = True
        min_value = 5.0  # filters out the 2-TON OUT
        since = None
        before = None
        dest = None
        limit = 10
        before_lt = None
        json = False

    async def go():
        async with _mock_client(handler) as c:
            await ton.cmd_tx(c, NS())

    asyncio.run(go())
    rows = [r for r in capsys.readouterr().out.strip().splitlines() if r]
    assert len(rows) == 1  # only the 10-TON OUT
    assert DEST_RAW in rows[0]
    assert "10" in rows[0]


def test_cmd_tx_dest_filter(capsys):
    handler = _paginating_handler(_tx_doc())

    class NS:
        addr = RAW
        in_ = False
        out = True
        min_value = 0
        since = None
        before = None
        dest = DEST_RAW
        limit = 10
        before_lt = None
        json = False

    async def go():
        async with _mock_client(handler) as c:
            await ton.cmd_tx(c, NS())

    asyncio.run(go())
    rows = [r for r in capsys.readouterr().out.strip().splitlines() if r]
    assert len(rows) == 1
    assert DEST_RAW in rows[0]


def test_cmd_tx_json_mode_prunes(capsys):
    # tx with heavy fields should come out pruned
    heavy_tx = {
        "lt": 100, "utime": 1_704_067_200,
        "hash": "abc",
        "compute_phase": {"success": True, "gas_used": 10},
        "action_phase": {"success": True},
        "state_update": {"boc": "BIG" * 1000},
        "block": "x",
        "total_fees": "123",
        "in_msg": None,
        "out_msgs": [
            {"destination": {"address": "0:BBB"}, "value": "2000000000",
             "fwd_fee": "1", "ihr_fee": "0",
             "message_content": {"decoded": {"comment": "ok"}},
             "raw_body": "BIG" * 500},
        ],
    }

    def handler(req):
        return httpx.Response(200, json={"transactions": [heavy_tx]})

    class NS:
        addr = RAW
        in_ = False
        out = True
        min_value = 0
        since = None
        before = None
        dest = None
        limit = 1
        before_lt = None
        json = True

    async def go():
        async with _mock_client(handler) as c:
            await ton.cmd_tx(c, NS())

    asyncio.run(go())
    out = capsys.readouterr().out.strip()
    parsed = json.loads(out)
    assert "compute_phase" not in parsed
    assert "state_update" not in parsed
    assert "total_fees" not in parsed
    assert parsed["out_msgs"][0]["destination"] == {"address": "0:BBB"}
    assert "fwd_fee" not in parsed["out_msgs"][0]
    assert "raw_body" not in parsed["out_msgs"][0]
    assert parsed["out_msgs"][0]["comment"] == "ok"
