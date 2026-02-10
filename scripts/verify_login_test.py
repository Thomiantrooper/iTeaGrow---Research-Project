import requests
import sys

BASE_URL = "http://localhost:8000"
LOGIN_URL = f"{BASE_URL}/api/users/login"

def test_login(username, password):
    print(f"Testing login for user: {username}...")
    try:
        response = requests.post(LOGIN_URL, json={
            "username": username,
            "password": password
        })
        
        if response.status_code == 200:
            data = response.json()
            if "access_token" in data:
                print(f"✅ SUCCESS: Login successful for '{username}'")
                print(f"   Token: {data['access_token'][:20]}...")
                return True
            else:
                print(f"❌ FAILURE: Login successful but no token found. Response: {data}")
                return False
        else:
            print(f"❌ FAILURE: Login failed. Status: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"❌ ERROR: Could not connect to backend at {BASE_URL}. Is it running?")
        return False
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    print("=== Verifying Backend Login ===")
    
    # Test valid credentials
    success_farmer = test_login("farmer", "farmer123")
    print("-" * 30)
    success_admin = test_login("admin", "admin123")
    print("-" * 30)
    
    # Test invalid credentials
    print("Testing invalid credentials...")
    response = requests.post(LOGIN_URL, json={
        "username": "farmer",
        "password": "wrongpassword"
    })
    if response.status_code == 401:
        print("✅ SUCCESS: Invalid password correctly rejected.")
    else:
        print(f"❌ FAILURE: expected 401 for bad password, got {response.status_code}")

    if success_farmer and success_admin:
        print("\n✅ OVERALL STATUS: Login system is Working.")
        sys.exit(0)
    else:
        print("\n❌ OVERALL STATUS: Login system is Failing.")
        sys.exit(1)
