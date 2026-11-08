#!/usr/bin/env python3
"""Draws the PortMaster cover (640x480) from a game screenshot: dimmed, with the title (ADR 0033)."""
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

shot_path, font_path, out_path = sys.argv[1:4]
shot = Image.open(shot_path).convert("RGB").resize((640, 480))

# Darken the screenshot, more towards the bottom, so the title reads.
shade = Image.new("RGB", (640, 480), (20, 6, 15))
mask = Image.linear_gradient("L").resize((640, 480))
cover = Image.composite(shade, shot, mask.point(lambda v: int(v * 0.75)))

font = ImageFont.truetype(font_path, 118)
font.set_variation_by_axes([900])
small = ImageFont.truetype(font_path, 26)
small.set_variation_by_axes([900])

glow = Image.new("RGBA", (640, 480), (0, 0, 0, 0))
draw = ImageDraw.Draw(glow)
title = "xpeedy"
width = draw.textlength(title, font=font)
x, y = (640 - width) / 2, 255
draw.text((x, y), title, font=font, fill=(226, 166, 58, 255))
blur = glow.filter(ImageFilter.GaussianBlur(10))
cover = Image.alpha_composite(cover.convert("RGBA"), blur)
cover = Image.alpha_composite(cover, glow)
draw = ImageDraw.Draw(cover)
tag = "a free tunnel racer"
draw.text(((640 - draw.textlength(tag, font=small)) / 2, 395), tag, font=small, fill=(241, 241, 244, 255))
cover.convert("RGB").save(out_path)
print("cover", out_path)
