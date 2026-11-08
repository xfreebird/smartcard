---
title: "Verifică prin MCP — Windows · Linie de comandă (CLI)"
sidebar_label: "Verifică prin MCP"
description: "Verifică un PDF sau XML și inspectează semnatarul și certificatul."
pagination_prev: "platforms/windows-cli/setup"
pagination_next: "platforms/windows-cli/mcp"
---



# Verifică prin MCP — Windows · Linie de comandă (CLI)

[Ghidurile platformei](../windows-cli.md) · [Instalare și conectarea cititorului](./setup.md)

Verifică un PDF sau XML și inspectează semnatarul și certificatul.

## Verifică și interpretează rezultatul

Verificarea offline pe Windows este oferită de MCP verify_document, nu de comanda normală verify. Configurează o rădăcină explicită și intrarea `{rootId,relativePath}`; citește integritatea, semnătura și lanțul. Originalele lipsă necesită rădăcina detașată explicită. Nu se folosește cititor/PIN și nu se verifică revocarea curentă.
