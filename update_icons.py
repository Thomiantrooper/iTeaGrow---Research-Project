import os
from PIL import Image

def generate_android_icons():
    source_logo_path = r'c:\Users\lenovo\OneDrive\Desktop\Disease\frontend\iTeaGrow---Research-Project\assets\images\tea.png'
    android_res_path = r'c:\Users\lenovo\OneDrive\Desktop\Disease\frontend\iTeaGrow---Research-Project\android\app\src\main\res'
    
    # Map mipmap folders to icon sizes (px)
    # mdpi: 48x48
    # hdpi: 72x72
    # xhdpi: 96x96
    # xxhdpi: 144x144
    # xxxhdpi: 192x192
    
    icon_configs = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    if not os.path.exists(source_logo_path):
        print(f"Error: Source image not found at {source_logo_path}")
        return

    try:
        img = Image.open(source_logo_path)
        print(f"Loaded source image {img.size}")
        
        for folder, size in icon_configs.items():
            folder_path = os.path.join(android_res_path, folder)
            if not os.path.exists(folder_path):
                os.makedirs(folder_path)
                print(f"Created directory {folder_path}")
            
            # Resize
            resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Save as ic_launcher.png
            icon_path = os.path.join(folder_path, 'ic_launcher.png')
            resized_img.save(icon_path)
            print(f"Saved {icon_path} ({size}x{size})")
            
    except Exception as e:
        print(f"Error generating icons: {e}")

if __name__ == "__main__":
    generate_android_icons()
