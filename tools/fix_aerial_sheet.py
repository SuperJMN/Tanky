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
    p.add_argument("--extrude", type=int, default=0, help="Extrude pixels around each frame to avoid texture bleeding")
    p.add_argument("--auto-slice", action="store_true", help="Auto-detect grid by scanning fully-empty rows/columns (recommended for irregular sheets)")
    p.add_argument("--anchor", choices=["center","bottom"], default="center", help="Vertical anchor inside each cell")
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


def find_separators(alpha, min_run=1):
    # Returns column separators (x indices) and row separators (y indices) where the line is fully transparent
    w, h = alpha.size
    cols = []
    for x in range(w):
        col = alpha.crop((x,0,x+1,h))
        if col.getbbox() is None:
            cols.append(x)
    rows = []
    for y in range(h):
        row = alpha.crop((0,y,w,y+1))
        if row.getbbox() is None:
            rows.append(y)
    return cols, rows


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

    frames = []
    max_w = 0
    max_h = 0

    if args.auto_slice:
        alpha = sheet.split()[-1]
        # Build separators lists and from them cell bounds
        col_seps, row_seps = find_separators(alpha)
        # Ensure 0 and W/H are included as boundaries
        col_bounds = sorted(set([0, W] + col_seps))
        row_bounds = sorted(set([0, H] + row_seps))
        # Build segments between consecutive transparent lines with at least 1px width/height
        cols = [(col_bounds[i], col_bounds[i+1]) for i in range(len(col_bounds)-1) if col_bounds[i+1] - col_bounds[i] > 0]
        rows = [(row_bounds[i], row_bounds[i+1]) for i in range(len(row_bounds)-1) if row_bounds[i+1] - row_bounds[i] > 0]
        # If auto detection failed to find grid, fallback to uniform
        if len(cols) != args.hframes or len(rows) != args.vframes:
            fw = W // args.hframes
            fh = H // args.vframes
            rows = [(v*fh, (v+1)*fh) for v in range(args.vframes)]
            cols = [(h*fw, (h+1)*fw) for h in range(args.hframes)]
    else:
        fw = W // args.hframes
        fh = H // args.vframes
        rows = [(v*fh, (v+1)*fh) for v in range(args.vframes)]
        cols = [(h*fw, (h+1)*fw) for h in range(args.hframes)]

    for rv in range(args.vframes):
        for ch in range(args.hframes):
            x0, x1 = cols[ch]
            y0, y1 = rows[rv]
            tile = sheet.crop((x0, y0, x1, y1))
            bb = bbox_nontransparent(tile)
            if bb is None:
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

    def extrude(tile: Image.Image, n: int) -> Image.Image:
        if n <= 0:
            return tile
        w, h = tile.size
        ext = Image.new("RGBA", (w + 2*n, h + 2*n), (0,0,0,0))
        ext.alpha_composite(tile, (n, n))
        # Edges
        left = tile.crop((0,0,1,h)).resize((n,h))
        right = tile.crop((w-1,0,w,h)).resize((n,h))
        top = tile.crop((0,0,w,1)).resize((w,n))
        bottom = tile.crop((0,h-1,w,h)).resize((w,n))
        ext.alpha_composite(left, (0, n))
        ext.alpha_composite(right, (n + w, n))
        ext.alpha_composite(top, (n, 0))
        ext.alpha_composite(bottom, (n, n + h))
        # Corners
        tl = tile.getpixel((0,0))
        tr = tile.getpixel((w-1,0))
        bl = tile.getpixel((0,h-1))
        br = tile.getpixel((w-1,h-1))
        Image.new("RGBA", (n,n), tl)
        for dx in range(n):
            for dy in range(n):
                pass
        # Fill corners as solid colors
        for x in range(n):
            for y in range(n):
                ext.putpixel((x, y), tl)
                ext.putpixel((x + n + w, y), tr)
                ext.putpixel((x, y + n + h), bl)
                ext.putpixel((x + n + w, y + n + h), br)
        return ext

    i = 0
    for v in range(args.vframes):
        for h in range(args.hframes):
            tile = extrude(frames[i], args.extrude)
            fx, fy = tile.size
            # Place in cell using requested anchor
            cx = h * cell_w + (cell_w - fx) // 2
            if args.anchor == "bottom":
                cy = v * cell_h + (cell_h - fy)
            else:
                cy = v * cell_h + (cell_h - fy) // 2
            out.alpha_composite(tile, (cx, cy))
            i += 1

    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    out.save(args.output)
    print(f"Wrote {args.output} with cell {cell_w}x{cell_h} ({args.hframes}x{args.vframes})")


if __name__ == "__main__":
    main()
