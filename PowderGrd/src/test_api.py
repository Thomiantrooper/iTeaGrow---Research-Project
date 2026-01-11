"""
Test client for Tea Grading API
Usage: python test_api.py
"""

import requests
import json
from pathlib import Path

# API Configuration
API_URL = "http://localhost:8000"

def test_health():
    """Test health check endpoint"""
    print("\n" + "="*60)
    print("Testing Health Check...")
    print("="*60)
    
    response = requests.get(f"{API_URL}/health")
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.status_code == 200

def test_get_grades():
    """Test get grades endpoint"""
    print("\n" + "="*60)
    print("Testing Get Grades...")
    print("="*60)
    
    response = requests.get(f"{API_URL}/grades")
    print(f"Status Code: {response.status_code}")
    data = response.json()
    
    print(f"\nAvailable Grades: {', '.join(data['grades'])}")
    print(f"\nDensity Standards:")
    for grade, standards in data['density_standards'].items():
        print(f"  {grade}: {standards['min']}-{standards['max']} g/L (optimal: {standards['optimal']})")
    
    print(f"\nBase Prices:")
    for grade, price in data['base_prices'].items():
        print(f"  {grade}: {price} per kg")
    
    return response.status_code == 200

def test_predict(image_path: str, weight: float, volume: float = 1.0):
    """Test prediction endpoint with image"""
    print("\n" + "="*60)
    print(f"Testing Prediction...")
    print("="*60)
    print(f"Image: {image_path}")
    print(f"Weight: {weight}g")
    print(f"Volume: {volume}L")
    
    if not Path(image_path).exists():
        print(f"❌ Error: Image file not found: {image_path}")
        return False
    
    try:
        with open(image_path, 'rb') as img:
            files = {'image': img}
            data = {
                'weight': weight,
                'volume': volume
            }
            
            response = requests.post(f"{API_URL}/predict", files=files, data=data)
            print(f"\nStatus Code: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"\n{'='*60}")
                print("GRADING RESULTS")
                print(f"{'='*60}")
                print(f"Grade: {result['grade']}")
                print(f"Confidence: {result['confidence']:.2f}%")
                print(f"\n{'Density Analysis':─^60}")
                print(f"Density Status: {result['density_status']}")
                print(f"Entered Weight: {result['entered_weight']}g")
                print(f"Actual Density: {result['standard_density_range']['actual']} g/L")
                print(f"Standard Range: {result['standard_density_range']['min']}-{result['standard_density_range']['max']} g/L")
                print(f"Optimal: {result['standard_density_range']['optimal']} g/L")
                print(f"Within Tolerance: {'✓ YES' if result['within_tolerance'] else '✗ NO'}")
                print(f"\n{'Pricing & Quality':─^60}")
                print(f"Price Category: {result['price_category']}")
                print(f"Price per kg: {result['price_per_kg']}")
                print(f"Quality Score: {result['quality_score']}/100")
                print(f"\n{'Recommendations':─^60}")
                print(f"{result['recommendations']}")
                print(f"{'='*60}\n")
                return True
            else:
                print(f"Error: {response.json()}")
                return False
                
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_check_density(grade: str, weight: float, volume: float = 1.0):
    """Test density check endpoint"""
    print("\n" + "="*60)
    print("Testing Density Check...")
    print("="*60)
    print(f"Grade: {grade}")
    print(f"Weight: {weight}g")
    print(f"Volume: {volume}L")
    
    data = {
        'grade': grade,
        'weight': weight,
        'volume': volume
    }
    
    response = requests.post(f"{API_URL}/check-density", data=data)
    print(f"\nStatus Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"\nGrade: {result['grade']}")
        print(f"Density Analysis: {json.dumps(result['density_analysis'], indent=2)}")
        print(f"Pricing: {json.dumps(result['pricing'], indent=2)}")
        return True
    else:
        print(f"Error: {response.json()}")
        return False

def run_test_scenarios():
    """Run various test scenarios"""
    print("\n" + "="*60)
    print("TEA GRADING API - TEST SUITE")
    print("="*60)
    
    # Test 1: Health check
    test_health()
    
    # Test 2: Get grades
    test_get_grades()
    
    # Test 3: Density check scenarios
    print("\n" + "="*60)
    print("SCENARIO 1: Excellent Density")
    print("="*60)
    test_check_density("BOP", 300, 1.0)  # Optimal
    
    print("\n" + "="*60)
    print("SCENARIO 2: Good Density")
    print("="*60)
    test_check_density("BOP", 310, 1.0)  # Slightly above optimal
    
    print("\n" + "="*60)
    print("SCENARIO 3: Below Standard (Low)")
    print("="*60)
    test_check_density("BOP", 250, 1.0)  # Too low
    
    print("\n" + "="*60)
    print("SCENARIO 4: Below Standard (High)")
    print("="*60)
    test_check_density("BOP", 350, 1.0)  # Too high
    
    # Test 4: Image prediction (if test image exists)
    test_image = "../data/test/test1.jpg"
    if Path(test_image).exists():
        print("\n" + "="*60)
        print("SCENARIO 5: Image Prediction with Good Density")
        print("="*60)
        test_predict(test_image, 305, 1.0)
        
        print("\n" + "="*60)
        print("SCENARIO 6: Image Prediction with Poor Density")
        print("="*60)
        test_predict(test_image, 400, 1.0)
    else:
        print(f"\n⚠️  Skipping image prediction test - test image not found: {test_image}")
        print("To test image prediction, provide a valid image path in test_predict()")

def interactive_test():
    """Interactive testing mode"""
    print("\n" + "="*60)
    print("INTERACTIVE TEST MODE")
    print("="*60)
    
    print("\n1. Test with image")
    print("2. Test density check only")
    print("3. Run all test scenarios")
    print("4. Exit")
    
    choice = input("\nEnter choice (1-4): ")
    
    if choice == "1":
        image_path = input("Enter image path: ")
        weight = float(input("Enter weight (grams): "))
        volume = float(input("Enter volume (liters, default 1.0): ") or "1.0")
        test_predict(image_path, weight, volume)
    elif choice == "2":
        grade = input("Enter grade (BOP/BOPF/Dust/Dust1/Fanning1/Pekoe): ")
        weight = float(input("Enter weight (grams): "))
        volume = float(input("Enter volume (liters, default 1.0): ") or "1.0")
        test_check_density(grade, weight, volume)
    elif choice == "3":
        run_test_scenarios()
    elif choice == "4":
        print("Exiting...")
        return
    else:
        print("Invalid choice")

if __name__ == "__main__":
    import sys
    
    print("""
╔══════════════════════════════════════════════════════════╗
║         TEA GRADING API - TEST CLIENT                    ║
║                                                          ║
║  Make sure the API server is running:                   ║
║  uvicorn app:app --reload                               ║
╚══════════════════════════════════════════════════════════╝
    """)
    
    # Check if API is running
    try:
        response = requests.get(f"{API_URL}/health", timeout=2)
        if response.status_code == 200:
            print("✓ API is running and healthy!\n")
        else:
            print("⚠️  API is running but returned unexpected status\n")
    except requests.exceptions.ConnectionError:
        print("❌ Error: Cannot connect to API. Please start the server first.")
        print(f"   Expected URL: {API_URL}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error checking API: {e}")
        sys.exit(1)
    
    # Run tests
    if len(sys.argv) > 1:
        if sys.argv[1] == "--auto":
            run_test_scenarios()
        else:
            print("Usage: python test_api.py [--auto]")
            print("  --auto: Run all test scenarios automatically")
            print("  (no args): Interactive mode")
    else:
        interactive_test()
