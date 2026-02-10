from PIL import Image, ImageDraw

def create_leaf_icon():
    # Size 1024x1024 for high res icon
    size = (1024, 1024)
    # Background color (White) or Transparent? 
    # Usually app icons have a background. The user wants "leaf logo" which is green.
    # Let's make a white background with a green leaf, or green background with white leaf.
    # The login screen has a green leaf icon.
    # Let's do a white background circle (since Android icons are often adaptive)
    # But for a simple PNG, let's do a full square image that can be masked.
    
    # White background
    img = Image.new('RGBA', size, (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw a green circle in the middle? No, let's just draw the leaf.
    # Actually, Android Adaptive icons usually have a background layer and a foreground layer.
    # But flutter_launcher_icons takes a single image and handles it.
    # If I provide a PNG with valid content, it should work.
    
    # Let's draw a nice Green Leaf.
    # Leaf color: #4CAF50 (Material Green 500)
    leaf_color = (76, 175, 80, 255)
    
    # Draw a leaf shape using two intersecting circles (arcs)
    # Center = 512, 512
    
    # Shape points for a generic leaf
    # Tip at (512, 100), Base at (512, 900)
    # Width control points...
    
    points = [
        (512, 150),  # Top tip
        (750, 400),  # Right bulge
        (512, 850),  # Bottom tip/stem base
        (274, 400),  # Left bulge
    ]
    
    draw.polygon(points, fill=leaf_color)
    
    # Add a stem
    draw.line([(512, 850), (512, 950)], fill=leaf_color, width=40)
    
    # Add a cutout or vein
    draw.line([(512, 150), (512, 850)], fill=(255, 255, 255, 128), width=10)

    # Save
    output_path = r'c:\Users\lenovo\OneDrive\Desktop\Disease\frontend\iTeaGrow---Research-Project\assets\images\app_logo.png'
    img.save(output_path)
    print(f"Icon saved to {output_path}")

if __name__ == "__main__":
    create_leaf_icon()
