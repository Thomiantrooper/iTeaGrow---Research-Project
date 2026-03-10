from PIL import Image
import colorsys

img_path = r"C:\Users\HP\Desktop\Tea Leaf Disease\Red Rust\IMG-20251122-WA0045.jpg"

def analyze():
    img = Image.open(img_path).convert("RGB")
    # Resize like Dart code: img.copyResize(image, width: 400)
    w, h = img.size
    new_h = int(h * (400 / w))
    img = img.resize((400, new_h))
    
    total = 400 * new_h
    leaf_pixels = 0
    green_pixels = 0
    rust_pixels = 0
    blister_pixels = 0
    dark_skipped = 0
    bright_skipped = 0
    desat_skipped = 0
    
    px = img.load()
    
    for y in range(new_h):
        for x in range(400):
            r, g, b = px[x, y]
            brightness = (r + g + b) / 3.0
            
            # RGB to HSV
            h_f, s_f, v_f = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)
            hue = h_f * 360
            sat = s_f * 255
            val = v_f * 255
            
            # Mask logic
            if brightness > 230 and sat < 35:
                bright_skipped += 1
                continue
            if brightness < 25 or brightness > 248:
                if brightness < 25: dark_skipped += 1
                else: bright_skipped += 1
                continue
            if sat < 18:
                desat_skipped += 1
                continue
                
            leaf_pixels += 1
            
            # Red Rust logic
            if ((hue >= 0 and hue <= 35) or (hue >= 340 and hue <= 360)) and sat > 40 and sat < 230 and val > 30 and val < 210:
                if r > g and r > (b * 0.9) and (r - g) > 10:
                    rust_pixels += 1
                    continue
            
            # Necrotic spot logic (added to block healthy override)
            if hue >= 10 and hue <= 50 and sat > 15 and val > 20 and val < 180:
                if r >= g and (r - g) > 5:
                    rust_pixels += 1
                    continue
                    
            # Green logic
            if hue >= 40 and hue <= 180 and sat > 25 and val > 20:
                green_pixels += 1
                
    effective = max(leaf_pixels, total if leaf_pixels <= 100 else leaf_pixels)
    g_score = green_pixels / effective
    r_score = rust_pixels / effective
    
    print(f"Total: {total}")
    print(f"Leaf px: {leaf_pixels} ({leaf_pixels/total*100:.1f}%)")
    print(f"- Bright/Over skips: {bright_skipped}")
    print(f"- Dark skips (<25): {dark_skipped}")
    print(f"- Desat skips (<18): {desat_skipped}")
    print(f"Green px: {green_pixels} (Score: {g_score*100:.1f}%)")
    print(f"Rust px: {rust_pixels} (Score: {r_score*100:.1f}%)")
    
if __name__ == "__main__":
    analyze()
