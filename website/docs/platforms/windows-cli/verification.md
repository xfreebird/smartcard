---
title: "Verify with MCP — Windows · Command line (CLI)"
sidebar_label: "Verify with MCP"
description: "Verify a PDF or XML and inspect its signer and certificate."
pagination_prev: "platforms/windows-cli/setup"
pagination_next: "platforms/windows-cli/mcp"
---



# Verify with MCP — Windows · Command line (CLI)

[Platform overview](../windows-cli.md) · [Installation and reader setup](./setup.md)

Verify a PDF or XML and inspect its signer and certificate.

## Verify and interpret the result

Windows offline verification is available through MCP verify_document, not the normal verify CLI command. Launch the host with an explicit root and supply input `{rootId,relativePath}`; inspect integrity/signature/chain fields. Missing originals require the explicit detached root. No reader/PIN is used. It does not check current revocation.
