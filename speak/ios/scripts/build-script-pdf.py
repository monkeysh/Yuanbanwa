#!/usr/bin/env python3
"""
Build 录音脚本.pdf from 录音脚本.md.

Constraints:
- Warm cream background (#F7F2EA), matches the app brand.
- Chinese via Arial Unicode (the PingFang.ttc on modern macOS uses
  PostScript outlines which reportlab can't parse — Arial Unicode covers
  the same character range).
- English serif (Times-Italic) for practice sentences — mirrors the app's
  typographic treatment and makes them pop.
- Emoji stripped from headings — Arial Unicode lacks emoji glyphs and
  they otherwise render as tofu.
"""

from __future__ import annotations
import re
import os
from pathlib import Path

from reportlab.lib.pagesizes import A4
from reportlab.lib.colors import HexColor
from reportlab.lib.units import mm
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.pdfmetrics import registerFontFamily
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
    KeepTogether, HRFlowable, Table, TableStyle,
)

MD_PATH = Path("/Users/gelili/Documents/Claude.English/Speak-ios/录音脚本/录音脚本.md")
PDF_PATH = Path("/Users/gelili/Documents/Claude.English/Speak-ios/录音脚本/录音脚本.pdf")

# Brand palette (cream day mode).
BG          = HexColor("#F7F2EA")
INK         = HexColor("#2B2722")
INK_SOFT    = HexColor("#6E665A")
INK_MUTED   = HexColor("#A59C8E")
ACCENT_DEEP = HexColor("#C55A30")
LINE        = HexColor("#E6DFD3")


# ---------- Font registration ----------------------------------------------

ZH_FONT = "ZH"
ZH_BOLD = "ZH-Bold"


def register_fonts():
    """Register a Chinese font + family for <b> tag support."""
    arial = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
    if not os.path.exists(arial):
        raise SystemExit(f"Missing CJK font at {arial}")
    pdfmetrics.registerFont(TTFont(ZH_FONT, arial))
    pdfmetrics.registerFont(TTFont(ZH_BOLD, arial))
    # This lets `<b>` tags in a Paragraph find a matching bold face and
    # actually render instead of falling back to a generic font that
    # can't draw CJK glyphs (→ tofu).
    registerFontFamily(ZH_FONT, normal=ZH_FONT, bold=ZH_BOLD,
                       italic=ZH_FONT, boldItalic=ZH_BOLD)


# ---------- Styles ---------------------------------------------------------

def make_styles():
    zh = ParagraphStyle("zh", fontName=ZH_FONT, fontSize=10.5,
                        leading=16, textColor=INK)
    zh_soft = ParagraphStyle("zh_soft", parent=zh, fontSize=9.5,
                             textColor=INK_SOFT, leading=14)
    zh_muted = ParagraphStyle("zh_muted", parent=zh, fontSize=9,
                              textColor=INK_MUTED, leading=13)
    title = ParagraphStyle("title", fontName=ZH_BOLD, fontSize=22,
                           textColor=INK, leading=28, spaceAfter=4)
    subtitle = ParagraphStyle("subtitle", fontName=ZH_FONT, fontSize=10.5,
                              textColor=INK_SOFT, leading=16, spaceAfter=14)
    h2 = ParagraphStyle("h2", fontName=ZH_BOLD, fontSize=16,
                        textColor=INK, leading=24, spaceBefore=16, spaceAfter=4)
    h2_sub = ParagraphStyle("h2_sub", fontName=ZH_FONT, fontSize=9.5,
                            textColor=INK_MUTED, leading=14, spaceAfter=10)
    en = ParagraphStyle("en", fontName="Times-Italic", fontSize=14,
                        textColor=INK, leading=20)
    num = ParagraphStyle("num", fontName="Helvetica", fontSize=11,
                         textColor=ACCENT_DEEP, leading=20)
    bullet = ParagraphStyle("bullet", parent=zh,
                            leftIndent=14, firstLineIndent=-10)
    return {
        "title": title, "subtitle": subtitle, "h2": h2, "h2_sub": h2_sub,
        "zh": zh, "zh_soft": zh_soft, "zh_muted": zh_muted,
        "en": en, "num": num, "bullet": bullet,
    }


# ---------- Page template --------------------------------------------------

def paint_bg(canvas, doc):
    """Flood the page with the cream background + footer."""
    canvas.saveState()
    canvas.setFillColor(BG)
    canvas.rect(0, 0, doc.pagesize[0], doc.pagesize[1], stroke=0, fill=1)
    canvas.restoreState()
    canvas.setFont(ZH_FONT, 8)
    canvas.setFillColor(INK_MUTED)
    canvas.drawCentredString(doc.pagesize[0] / 2, 12 * mm,
                             f"原版娃口语 · 录音脚本   ·   {doc.page}")


# ---------- Inline markdown helpers ----------------------------------------

# Emoji that Arial Unicode lacks — strip so they don't render as tofu.
EMOJI_RE = re.compile(
    "["
    "\U0001F300-\U0001FAFF"    # misc symbols, pictographs, flags
    "\U00002600-\U000027BF"    # misc symbols incl ✨ ☀ ☾ ✅
    "\U0001F600-\U0001F64F"    # emoticons
    "\U0001F680-\U0001F6FF"    # transport
    "\u2600-\u26FF\u2700-\u27BF"
    "\uFE00-\uFE0F"            # variation selectors (VS-1..VS-16)
    "\u200D"                   # zero-width joiner
    "]",
    flags=re.UNICODE,
)


def strip_emoji(s: str) -> str:
    return EMOJI_RE.sub("", s).strip()


def escape_html(s: str) -> str:
    return (s.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;"))


def inline_md(s: str) -> str:
    """**bold** and `code`. Escape HTML. Strip emoji (Arial Unicode has
    no emoji glyphs — they'd render as tofu). No font swap inside code —
    we color and outline it instead so Chinese inside `code` still renders."""
    s = strip_emoji(s)
    s = escape_html(s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", s)
    # For `code`: keep the same font (so CJK still works), just color it and
    # add a tiny smaller size. No Helvetica swap because inline Helvetica on
    # Chinese characters = tofu.
    s = re.sub(
        r"`([^`]+?)`",
        r'<font size="9.5" color="#C55A30">\1</font>',
        s,
    )
    return s


# ---------- Markdown → flowables ------------------------------------------

def build_story(md: str, S: dict):
    story = []
    lines = md.splitlines()
    i = 0

    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()

        if not stripped:
            i += 1
            continue

        # Title
        if stripped.startswith("# "):
            story.append(Paragraph(inline_md(strip_emoji(stripped[2:])),
                                    S["title"]))
            i += 1
            continue

        # Blockquote → subtitle
        if stripped.startswith("> "):
            story.append(Paragraph(inline_md(strip_emoji(stripped[2:])),
                                    S["subtitle"]))
            i += 1
            continue

        # Section heading
        if stripped.startswith("## "):
            title_text = strip_emoji(stripped[3:])
            story.append(Spacer(1, 4))
            story.append(HRFlowable(width="100%", thickness=0.6,
                                     color=LINE, spaceBefore=4, spaceAfter=10))
            story.append(Paragraph(inline_md(title_text), S["h2"]))
            # Collect following meta lines that start with **label**:
            meta: list[str] = []
            j = i + 1
            while j < len(lines):
                peek = lines[j].strip()
                if peek.startswith("**") and "**" in peek[2:]:
                    meta.append(peek)
                    j += 1
                elif not peek:
                    # Blank line ends the meta block.
                    break
                else:
                    break
            if meta:
                combined = "  ·  ".join(inline_md(m) for m in meta)
                story.append(Paragraph(combined, S["h2_sub"]))
                i = j
            else:
                i += 1
            continue

        # Horizontal rule
        if stripped == "---":
            story.append(HRFlowable(width="100%", thickness=0.6, color=LINE,
                                     spaceBefore=10, spaceAfter=12))
            i += 1
            continue

        # Numbered sentence: handle both "1. word" + optional indented zh line.
        m = re.match(r"^(\d+)\.\s+(.*)$", stripped)
        if m:
            num = int(m.group(1))
            body_text = m.group(2)
            zh_text = None
            # If the next line is indented (3+ spaces) and plain (not another
            # number, not a bullet), treat it as the zh gloss.
            if i + 1 < len(lines):
                nxt_raw = lines[i + 1]
                if nxt_raw.startswith("   "):
                    nxt_stripped = nxt_raw.strip()
                    if not re.match(r"^\d+\.", nxt_stripped) and not nxt_stripped.startswith("- "):
                        zh_text = nxt_stripped
                        i += 1
            # Decide style: sentence pair (has zh) vs. prose list (no zh).
            if zh_text and not contains_cjk(body_text):
                story.append(sentence_row(num, body_text, zh_text, S))
            else:
                # Numbered instruction (e.g. 录音方法 list). No separate zh
                # underneath — treat body as a single paragraph.
                combined = body_text + ("  " + zh_text if zh_text else "")
                story.append(prose_numbered_row(num, combined, S))
            i += 1
            continue

        # Bullet
        if stripped.startswith("- "):
            text = re.sub(r"^\[\s?\]\s*", "", stripped[2:])  # drop checkbox
            story.append(Paragraph("• " + inline_md(text), S["bullet"]))
            i += 1
            continue

        # Generic paragraph.
        story.append(Paragraph(inline_md(stripped), S["zh"]))
        i += 1

    return story


def contains_cjk(s: str) -> bool:
    for ch in s:
        if "\u4e00" <= ch <= "\u9fff":
            return True
    return False


def sentence_row(num: int, en: str, zh: str, S: dict):
    """[num]  English (serif)  /  Chinese underneath"""
    en_para = Paragraph(escape_html(en), S["en"])
    zh_para = Paragraph(escape_html(zh), S["zh_soft"])
    num_para = Paragraph(f"{num:02d}", S["num"])
    t = Table(
        [[num_para, [en_para, Spacer(1, 2), zh_para]]],
        colWidths=[12 * mm, None],
    )
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    return KeepTogether(t)


def prose_numbered_row(num: int, text: str, S: dict):
    """[num]  Chinese instruction (no separate English line)."""
    num_para = Paragraph(f"{num:02d}", S["num"])
    body = Paragraph(inline_md(text), S["zh"])
    t = Table([[num_para, body]], colWidths=[12 * mm, None])
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 0),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    return KeepTogether(t)


# ---------- Main -----------------------------------------------------------

def main():
    register_fonts()
    styles = make_styles()
    md = MD_PATH.read_text(encoding="utf-8")

    PDF_PATH.parent.mkdir(parents=True, exist_ok=True)
    doc = BaseDocTemplate(
        str(PDF_PATH),
        pagesize=A4,
        leftMargin=22 * mm, rightMargin=22 * mm,
        topMargin=20 * mm, bottomMargin=22 * mm,
        title="原版娃口语 · 录音脚本",
        author="原版娃",
        subject="跟读示范录音脚本 (阿黛 / 小何)",
    )
    frame = Frame(doc.leftMargin, doc.bottomMargin,
                  doc.width, doc.height, id="body")
    doc.addPageTemplates([PageTemplate(id="main", frames=[frame],
                                        onPage=paint_bg)])

    story = build_story(md, styles)
    doc.build(story)
    print(f"wrote {PDF_PATH} ({PDF_PATH.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
