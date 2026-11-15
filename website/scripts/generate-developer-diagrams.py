#!/usr/bin/env python3
"""Generate the public handbook's self-contained, accessible SVG diagrams."""

from html import escape
from pathlib import Path

OUTPUT = Path(__file__).resolve().parents[1] / "static/img/developers"


def text(x, y, lines, *, size=18, color="#172554", anchor="start", weight=400):
    if isinstance(lines, str):
        lines = [lines]
    spans = "".join(
        f'<tspan x="{x}" dy="{0 if i == 0 else 25}">{escape(line)}</tspan>'
        for i, line in enumerate(lines)
    )
    return (f'<text x="{x}" y="{y}" font-size="{size}" fill="{color}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{spans}</text>')


def rect(x, y, w, h, fill="#ffffff", stroke="#cbd5e1", radius=12):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" '
            f'fill="{fill}" stroke="{stroke}"/>')


def arrow(x1, y1, x2, y2, *, reply=False):
    dash = ' stroke-dasharray="7 5"' if reply else ""
    return (f'<path d="M{x1},{y1} L{x2},{y2}" fill="none" stroke="#3459a6" '
            f'stroke-width="2" marker-end="url(#arrow)"{dash}/>')


def svg(name, title, description, height, content):
    document = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="{height}" viewBox="0 0 1000 {height}" role="img" aria-labelledby="title description">
<title id="title">{escape(title)}</title>
<desc id="description">{escape(description)}</desc>
<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 Z" fill="#3459a6"/></marker></defs>
<rect width="1000" height="{height}" rx="16" fill="#f8fafc"/>
<g font-family="system-ui, -apple-system, Segoe UI, sans-serif">
{''.join(content)}
</g></svg>
'''
    (OUTPUT / name).write_text(document, encoding="utf-8")


def architecture():
    parts = [
        text(32, 44, "eSemnBun · component architecture", size=28, weight=700),
        text(32, 77, "Native interfaces, shared contracts, platform-specific adapters", color="#475569"),
    ]
    layers = [
        (110, "01  PRESENTATION", "#eef2ff", [
            ("Apple", "SwiftUI · AppKit / UIKit"),
            ("Android / Windows", "Compose / WinUI 3"),
            ("Linux / automation", "GTK4 · CLI · MCP")]),
        (285, "02  APPLICATION SERVICES", "#eff6ff", [
            ("State and workflow", "Selection · batch · progress"),
            ("Authorization", "Consent · PIN vault adapter"),
            ("Integration", "Files · history · bridge host")]),
        (460, "03  CRYPTOGRAPHIC CORE", "#ecfdf5", [
            ("Card session", "CosmoXCard · secure channel"),
            ("Document formats", "PAdES · XAdES · validation"),
            ("Service protocols", "TSA / CRL / OCSP · bridge")]),
        (635, "04  PLATFORM ADAPTERS", "#fff7ed", [
            ("Card transport", "CTK · PC/SC · USB CCID"),
            ("Native capabilities", "Crypto · files · protected store"),
            ("Network transport", "HTTP · sockets · loopback TLS")]),
        (810, "05  OUTSIDE THE APPLICATION", "#f1f5f9", [
            ("Reader and ID card", "Private signing key stays here"),
            ("Operating system", "Documents · credential store"),
            ("PKI services", "Timestamp · revocation data")]),
    ]
    for y, label, fill, cards in layers:
        parts += [rect(32, y, 936, 140, fill), text(52, y + 29, label, size=15, weight=700)]
        for index, (heading, subtitle) in enumerate(cards):
            x = 48 + index * 306
            parts += [rect(x, y + 45, 292, 78), text(x + 14, y + 73, heading, weight=650),
                      text(x + 14, y + 100, subtitle, size=16, color="#475569")]
        if y != 810:
            parts += [arrow(500, y + 143, 500, y + 171)]
    parts += [text(32, 986, "Arrows: calls / data flow across responsibilities. Most layers share one process.", size=16, color="#475569"),
              text(32, 1013, "Swift on Apple/Linux · Kotlin on Android · C# on Windows · common byte vectors", size=16, color="#475569")]
    svg("architecture.svg", "eSemnBun layered component architecture",
        "Presentation calls application services, which coordinate card and document core logic through platform adapters. "
        "External systems are the reader and ID card, operating-system storage and remote PKI services. "
        "The private signing key remains on the ID card.", 1040, parts)


def sequence():
    parts = [text(32, 44, "From approval to a signed document", size=28, weight=700),
             text(32, 77, "Logical signing sequence · replies dashed · card arrows pass through the reader", size=17, color="#475569")]
    lanes = [(130, ["Person / native UI"]), (375, ["Signing service", "and format core"]),
             (620, ["Reader / ID card"]), (865, ["Timestamp authority"])]
    for x, label in lanes:
        parts += [rect(x - 112, 105, 224, 70, "#eef2ff"), text(x, 135, label, size=17, anchor="middle", weight=650),
                  f'<path d="M{x},175 V1240" stroke="#94a3b8" stroke-dasharray="5 6"/>']

    def phase(y, label, fill="#e2e8f0"):
        parts.extend([rect(20, y, 960, 34, fill, fill, 6), text(34, y + 23, label, size=16, weight=650)])

    def message(y, sender, receiver, label, reply=False):
        parts.extend([text((sender + receiver) / 2, y - (39 if len(label) > 1 else 14), label,
                           size=16, anchor="middle"), arrow(sender, y, receiver, y, reply=reply)])

    phase(195, "1  Freeze input and obtain consent")
    message(290, 130, 375, ["Choose document / identity", "Approve the signing request"])
    phase(315, "2  Establish the protected card session")
    message(410, 375, 620, ["Select application", "Read initialization data"])
    message(470, 375, 620, ["Challenge + mutual auth", "Derive session keys / SSC"])
    message(520, 620, 375, ["Authentication response"], reply=True)
    phase(535, "3  Check identity before sending the PIN", "#dcfce7")
    message(625, 375, 620, ["Read signing certificate", "through secure messaging"])
    message(680, 620, 375, ["Certificate bytes"], reply=True)
    parts += [rect(230, 700, 290, 58, "#fff7ed"), text(375, 725, ["Compare with approved identity", "Mismatch: stop before VERIFY"], size=15, anchor="middle")]
    phase(780, "4  Authorize and sign inside the card")
    message(875, 375, 620, ["Protected VERIFY PIN", "Wrong / blocked PIN: stop"])
    message(935, 375, 620, ["Set signing environment", "Sign encoded DigestInfo"])
    message(990, 620, 375, ["RSA signature bytes"], reply=True)
    phase(1010, "5  Add timestamp when required, assemble and save")
    message(1090, 375, 865, ["RFC 3161 request over signature digest"])
    message(1140, 865, 375, ["Timestamp token"], reply=True)
    message(1215, 375, 130, ["Assemble PDF / XML", "Save and report result"], reply=True)
    parts += [text(32, 1280, "The card receives an encoded digest, not the whole document. Its private key never leaves it.", size=16, color="#475569"),
              text(32, 1307, "Certificate discovery may use an earlier session; the signing path rechecks the selected identity.", size=16, color="#475569")]
    svg("card-sequence.svg", "eSemnBun identity-card signing sequence",
        "The person chooses a document and approves. The service authenticates a card session, reads and compares the "
        "certificate, verifies the PIN over secure messaging, and asks the card to sign DigestInfo. "
        "A mismatch or PIN failure stops signing. The service obtains a timestamp when required and saves PDF or XML output.",
        1335, parts)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    architecture()
    sequence()
