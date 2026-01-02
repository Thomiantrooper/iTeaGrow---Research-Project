#!/usr/bin/env python3
"""
Quick Start Script
===================
Automated setup and testing of the Tea Leaf Disease Detection System.
Run this script to get started quickly!
"""

import os
import sys
import subprocess
import platform
from pathlib import Path
import shutil


class Colors:
    """Console colors."""
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BLUE = "\033[94m"
    BOLD = "\033[1m"
    END = "\033[0m"


def print_step(step_num, total, message):
    """Print a step header."""
    print(f"\n{Colors.BLUE}{Colors.BOLD}[{step_num}/{total}] {message}{Colors.END}")
    print("-" * 60)


def print_success(message):
    """Print success message."""
    print(f"{Colors.GREEN}✓ {message}{Colors.END}")


def print_warning(message):
    """Print warning message."""
    print(f"{Colors.YELLOW}⚠ {message}{Colors.END}")


def print_error(message):
    """Print error message."""
    print(f"{Colors.RED}✗ {message}{Colors.END}")


def run_command(cmd, check=True, capture=False):
    """Run a shell command."""
    try:
        if capture:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            return result.returncode == 0, result.stdout
        else:
            result = subprocess.run(cmd, shell=True)
            return result.returncode == 0, ""
    except Exception as e:
        return False, str(e)


def check_python():
    """Check Python version."""
    version = sys.version_info
    if version.major >= 3 and version.minor >= 9:
        print_success(f"Python {version.major}.{version.minor}.{version.micro}")
        return True
    else:
        print_error(f"Python 3.9+ required (found {version.major}.{version.minor})")
        return False


def check_node():
    """Check Node.js installation."""
    success, output = run_command("node --version", capture=True)
    if success:
        print_success(f"Node.js {output.strip()}")
        return True
    else:
        print_warning("Node.js not found - mobile app won't work")
        return False


def check_docker():
    """Check Docker installation."""
    success, output = run_command("docker --version", capture=True)
    if success:
        print_success(f"Docker {output.strip().split()[-1] if output else 'installed'}")
        return True
    else:
        print_warning("Docker not found - backend services won't work")
        return False


def check_gpu():
    """Check GPU availability."""
    try:
        import torch
        if torch.cuda.is_available():
            gpu_name = torch.cuda.get_device_name(0)
            print_success(f"CUDA GPU: {gpu_name}")
            return True
        else:
            print_warning("No CUDA GPU - training will be slower on CPU")
            return False
    except ImportError:
        print_warning("PyTorch not installed yet")
        return False


def setup_virtual_environment():
    """Create and activate virtual environment."""
    venv_path = Path("venv")

    if not venv_path.exists():
        print("Creating virtual environment...")
        run_command(f"{sys.executable} -m venv venv")

    # Determine activate script
    if platform.system() == "Windows":
        activate = "venv\\Scripts\\activate.bat"
        pip = "venv\\Scripts\\pip.exe"
    else:
        activate = "source venv/bin/activate"
        pip = "venv/bin/pip"

    print_success(f"Virtual environment ready at {venv_path}")
    print(f"  To activate: {activate}")

    return pip


def install_dependencies(pip):
    """Install Python dependencies."""
    print("Installing Python packages (this may take a few minutes)...")

    # Core packages first
    core_packages = [
        "ultralytics",
        "torch",
        "torchvision",
        "opencv-python",
        "Pillow",
        "numpy",
        "pyyaml",
    ]

    for pkg in core_packages:
        success, _ = run_command(f"{pip} install {pkg}", capture=True)
        if success:
            print(f"  ✓ {pkg}")
        else:
            print(f"  ✗ {pkg}")

    # Install remaining from requirements.txt
    if Path("requirements.txt").exists():
        run_command(f"{pip} install -r requirements.txt", capture=True)

    print_success("Dependencies installed")


def setup_dataset():
    """Setup dataset directory."""
    data_path = Path("data")

    if not data_path.exists() or not any(data_path.iterdir()):
        print("Creating dataset structure...")
        run_command(f"{sys.executable} scripts/setup_dataset.py")
        print_success("Dataset structure created")

        # Ask about demo data
        print("\nNo training data found.")
        response = input("Generate demo data for testing? [Y/n]: ").strip().lower()

        if response != "n":
            print("Generating demo data (100 images)...")
            run_command(f"{sys.executable} scripts/create_demo_data.py --train 100 --val 30 --test 20")
            print_success("Demo data generated")
    else:
        print_success("Dataset directory exists")

        # Verify
        run_command(f"{sys.executable} scripts/verify_dataset.py")


def setup_environment_config():
    """Setup environment configuration."""
    env_file = Path(".env")
    env_example = Path("config/.env.example")

    if not env_file.exists() and env_example.exists():
        shutil.copy(env_example, env_file)
        print_success("Created .env from template")
        print("  Edit .env to configure credentials")
    elif env_file.exists():
        print_success(".env file exists")


def train_model():
    """Train the model."""
    models_dir = Path("runs")
    has_model = models_dir.exists() and any(models_dir.glob("tea_disease_*/weights/best.pt"))

    if has_model:
        print_success("Trained model found")
        return True

    response = input("\nNo trained model found. Train now? [Y/n]: ").strip().lower()

    if response != "n":
        epochs = input("Number of training epochs [50]: ").strip() or "50"
        print(f"\nTraining model for {epochs} epochs...")
        print("This may take a while depending on your hardware.\n")

        success, _ = run_command(
            f"{sys.executable} scripts/train_model.py --data ./data --output ./runs --epochs {epochs} --batch-size 8"
        )

        if success:
            print_success("Model training complete!")
            return True
        else:
            print_error("Training failed - check the error messages above")
            return False
    else:
        print_warning("Skipping training")
        return False


def start_backend():
    """Start backend services."""
    response = input("\nStart backend services with Docker? [Y/n]: ").strip().lower()

    if response != "n":
        success, _ = run_command("docker-compose up -d")
        if success:
            print_success("Backend services started")
            print("\n  API:          http://localhost:8000")
            print("  API Docs:     http://localhost:8000/docs")
            print("  MinIO:        http://localhost:9001")
            print("  Grafana:      http://localhost:3000")
            return True
        else:
            print_error("Failed to start Docker services")
            return False
    else:
        print_warning("Skipping backend startup")
        return False


def test_system():
    """Run tests."""
    print("\nRunning inference test...")

    # Find a test image
    test_images = list(Path("data/images/test").glob("*.jpg"))

    if test_images:
        run_command(f"{sys.executable} scripts/test_inference.py --image {test_images[0]}")
    else:
        print_warning("No test images found")


def print_next_steps():
    """Print next steps."""
    print("\n" + "=" * 60)
    print(f"{Colors.GREEN}{Colors.BOLD}SETUP COMPLETE!{Colors.END}")
    print("=" * 60)

    print(f"""
{Colors.BOLD}Next Steps:{Colors.END}

1. {Colors.YELLOW}Add Real Training Data:{Colors.END}
   - Add tea leaf images to data/images/train/
   - Add labels to data/labels/train/
   - Use LabelImg or Roboflow for annotation
   - Run: python scripts/verify_dataset.py

2. {Colors.YELLOW}Train with Real Data:{Colors.END}
   python scripts/train_model.py --data ./data --epochs 100

3. {Colors.YELLOW}Test the Model:{Colors.END}
   python scripts/test_inference.py --image path/to/image.jpg

4. {Colors.YELLOW}Run Mobile App:{Colors.END}
   cd mobile_app
   npm install
   npx expo start

5. {Colors.YELLOW}Deploy to Production:{Colors.END}
   - Configure .env with production credentials
   - Deploy with: docker-compose -f docker-compose.prod.yml up -d

{Colors.BOLD}Documentation:{Colors.END}
- README.md - Project overview
- SETUP_GUIDE.md - Detailed setup instructions
- ARCHITECTURE.md - System architecture

{Colors.BOLD}Need Help?{Colors.END}
- Check docs in the docs/ folder
- Review error messages carefully
- Ensure all prerequisites are installed
""")


def main():
    """Main setup routine."""
    print("=" * 60)
    print(f"{Colors.GREEN}{Colors.BOLD}TEA LEAF DISEASE DETECTION SYSTEM{Colors.END}")
    print(f"{Colors.GREEN}Quick Start Setup{Colors.END}")
    print("=" * 60)

    total_steps = 8

    # Step 1: Check prerequisites
    print_step(1, total_steps, "Checking Prerequisites")
    check_python()
    check_node()
    check_docker()

    # Step 2: Setup virtual environment
    print_step(2, total_steps, "Setting Up Virtual Environment")
    pip = setup_virtual_environment()

    # Step 3: Install dependencies
    print_step(3, total_steps, "Installing Dependencies")
    install_dependencies(pip)

    # Step 4: Check GPU
    print_step(4, total_steps, "Checking GPU")
    check_gpu()

    # Step 5: Setup dataset
    print_step(5, total_steps, "Setting Up Dataset")
    setup_dataset()

    # Step 6: Setup configuration
    print_step(6, total_steps, "Setting Up Configuration")
    setup_environment_config()

    # Step 7: Train model
    print_step(7, total_steps, "Model Training")
    train_model()

    # Step 8: Start backend (optional)
    print_step(8, total_steps, "Backend Services")
    start_backend()

    # Test
    test_system()

    # Print next steps
    print_next_steps()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nSetup cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n\nError during setup: {e}")
        sys.exit(1)
