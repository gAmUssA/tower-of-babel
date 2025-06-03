#!/usr/bin/env python
"""
Script to check Python environment and package availability
"""

import sys
import os
import importlib.util
import subprocess

def check_package(package_name):
    """Check if a package is installed and importable"""
    spec = importlib.util.find_spec(package_name)
    if spec is None:
        print(f"❌ Package {package_name} is NOT installed or importable")
        return False
    else:
        print(f"✅ Package {package_name} is installed and importable")
        return True

def main():
    """Main function to check environment"""
    print(f"Python version: {sys.version}")
    print(f"Python executable: {sys.executable}")
    print(f"Python path: {sys.path}")
    print("\nChecking required packages:")
    
    required_packages = [
        "fastapi",
        "uvicorn",
        "dotenv",
        "python_dotenv",
        "confluent_kafka",
        "pydantic"
    ]
    
    for package in required_packages:
        check_package(package)
    
    print("\nChecking pip installed packages:")
    try:
        result = subprocess.run([sys.executable, "-m", "pip", "list"], 
                               capture_output=True, text=True, check=True)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running pip list: {e}")
    
    print("\nChecking environment variables:")
    for key, value in os.environ.items():
        if key.startswith("PYTHON") or key.startswith("PATH"):
            print(f"{key}={value}")

if __name__ == "__main__":
    main()
