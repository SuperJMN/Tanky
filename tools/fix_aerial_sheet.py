#!/usr/bin/env python3
import argparse
from PIL import Image
import os

def parse_args():
    p = argparse.ArgumentParser(description="Fix spritesheet grid by trimming per-frame borders and re-packing into uniform cells")
    p.add_argument("--input", required=True, help="Input spritesheet path")
    p.add_argument("--output", required=True, help="Output spritesheet path")
    p.add_argument("--hframes", type=int, required=True, help="Frames horizontally")
    p.add_argument("--vframes", type=int, required=True, help="Frames vertically")
    p.add_argument("--tolerance", type=int, default=8, help="RGB tolerance when keying background color")
    p.add_argument("--bg", type=str, default=None, help="Background color R,G,B (default: sample top-left)")
    p.add_argument("--pad", type=int, default=0, help="Padding inside each output cell (pixels)")
    return p.parse_args()


def within(c, ref, tol):
    return all(abs(int(c[i]) - int(ref[i])) <= tol for i in range(3))


def key_background(img, bg, tol):
    # Ensure RGBA
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if within((r, g, b), bg, tol):
                px[x, y] = (r, g, b, 0)
    return img


def bbox_nontransparent(tile: Image.Image):
    # Returns bounding box of non-transparent pixels or None
    alpha = tile.split()[-1]
    bb = alpha.getbbox()
    return bb  # (l,t,r,b) or None


def main():
    args = parse_args()
    sheet = Image.open(args.input)

    if args.bg:
        bg = tuple(map(int, args.bg.split(",")))
    else:
        # Sample top-left pixel as background
        bg = sheet.convert("RGB").getpixel((0, 0))

    sheet = key_background(sheet, bg, args.tolerance)

    W, H = sheet.size
    fw = W // args.hframes
    fh = H // args.vframes

    frames = []
    max_w = 0
    max_h = 0

    for v in range(args.vframes):
        for h in range(args.hframes):
            x = h * fw
            y = v * fh
            tile = sheet.crop((x, y, x + fw, y + fh))
            bb = bbox_nontransparent(tile)
            if bb is None:
                # Empty tile; keep as is
                cropped = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
            else:
                cropped = tile.crop(bb)
            frames.append(cropped)
            max_w = max(max_w, cropped.size[0])
            max_h = max(max_h, cropped.size[1])

    cell_w = max_w + args.pad * 2
    cell_h = max_h + args.pad * 2

    out_w = cell_w * args.hframes
    out_h = cell_h * args.vframes
    out = Image.new("RGBA", (out_w, out_h), (0, 0, 0, 0))

    i = 0
    for v in range(args.vframes):
        for h in range(args.hframes):
            fx, fy = frames[i].size
            # Center in cell
            cx = h * cell_w + (cell_w - fx) // 2
            cy = v * cell_h + (cell_h - fy) // 2
            out.alpha_composite(frames[i], (cx, cy))
            i += 1

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    out.save(args.output)
    print(f"Wrote {args.output} with cell {cell_w}x{cell_h} ({args.hframes}x{args.vframes})")


if __name__ == "__main__":
    main()
