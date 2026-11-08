#!/usr/bin/env python3
"""No-card stdio smoke/negative tests. Pass the already built native helper path."""
import json
import pathlib
import select
import subprocess
import sys
import tempfile

binary = pathlib.Path(sys.argv[1]).resolve()
meta = {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}

def receive(process):
    assert select.select([process.stdout], [], [], 10)[0], "response timeout"
    line = process.stdout.readline()
    assert line, "helper exited unexpectedly"
    return json.loads(line)

def send(process, method, params=None, request_id=1):
    value = {"jsonrpc": "2.0", "id": request_id, "method": method, "params": {"_meta": meta, **(params or {})}}
    process.stdin.write(json.dumps(value).encode() + b"\n")
    process.stdin.flush()
    return receive(process)

with tempfile.TemporaryDirectory() as temporary:
    root = pathlib.Path(temporary).resolve()
    (root / "unsigned.pdf").write_bytes(b"%PDF-1.7\n%%EOF\n")
    (root / "link.pdf").symlink_to(root / "unsigned.pdf")
    process = subprocess.Popen([str(binary), "--root", f"docs={root}"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    assert send(process, "server/discover")["result"]["supportedVersions"] == ["2026-07-28", "2025-11-25"]
    names = {tool["name"] for tool in send(process, "tools/list")["result"]["tools"]}
    assert "verify_document" in names and "sign_document" not in names
    for path, expected in [("unsigned.pdf", True), ("../outside.pdf", False), ("link.pdf", False)]:
        response = send(process, "tools/call", {"name": "verify_document", "arguments": {"input": {"rootId": "docs", "relativePath": path}}})
        assert response["result"]["structuredContent"]["ok"] is expected
    response = send(process, "tools/call", {"name": "prepare_signing", "arguments": {"input": {"rootId": "docs", "relativePath": "unsigned.pdf"}, "format": "PAdES-T", "pin": "sentinel"}})
    assert response["result"]["isError"] and "sentinel" not in json.dumps(response)
    process.stdin.write(b"not json\n")
    process.stdin.flush()
    assert receive(process)["error"]["code"] == -32700
    process.stdin.close()
    assert process.wait(timeout=10) == 0
    assert process.stderr.read() == b""
    legacy = subprocess.Popen([str(binary), "--root", f"docs={root}"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    def legacy_call(method, params=None):
        value = {"jsonrpc": "2.0", "id": 20, "method": method}
        if params is not None:
            value["params"] = params
        legacy.stdin.write(json.dumps(value).encode() + b"\n")
        legacy.stdin.flush()
        return receive(legacy)
    initialized = legacy_call("initialize", {"protocolVersion": "2025-11-25", "capabilities": {}, "clientInfo": {"name": "test", "version": "1"}})
    assert initialized["result"]["protocolVersion"] == "2025-11-25" and "resultType" not in initialized["result"]
    legacy.stdin.write(b'{"jsonrpc":"2.0","method":"notifications/initialized"}\n')
    legacy.stdin.flush()
    listing = legacy_call("tools/list")
    assert "resultType" not in listing["result"] and "_meta" not in listing["result"]
    verified = legacy_call("tools/call", {"name": "verify_document", "arguments": {"input": {"rootId": "docs", "relativePath": "unsigned.pdf"}}})
    assert verified["result"]["structuredContent"]["ok"] is True
    legacy.stdin.close()
    assert legacy.wait(timeout=10) == 0 and legacy.stderr.read() == b""
    oversized = subprocess.Popen([str(binary)], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, error = oversized.communicate(b"x" * 65537, timeout=10)
    assert oversized.returncode != 0 and output == b"" and b"frame limit" in error
    # Secrets must never be accepted through tool schemas, including when unattended is off.
    for flags in [
        ["--allow-unattended-signing"],
        ["--pin-source", "env:UNSET_TEST_VARIABLE"],
        ["--allow-unattended-signing", "--allow-unattended-signing"],
        ["--allow-unattended-signing", "--signing-certificate-sha256", "malformed"],
        ["--allow-unattended-signing", "--signing-certificate-sha256"],
    ]:
        invalid = subprocess.run([str(binary), *flags], capture_output=True, timeout=10)
        assert invalid.returncode != 0 and invalid.stdout == b""
print("MCP process checks passed (no card or secret access).")
