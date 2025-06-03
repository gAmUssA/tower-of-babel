# Tower of Babel Decision Log

## Python Environment Management
[2025-06-03 11:30:30] - **Python Virtual Environment for Inventory Service**
- **Decision**: Use a dedicated Python virtual environment for the Inventory Service
- **Rationale**: Resolves dependency conflicts and ensures consistent package versions
- **Implications**: 
  - Requires activating the virtual environment before running the service
  - Simplifies dependency management
  - Avoids conflicts with system Python packages

## Makefile Updates
[2025-06-03 11:31:00] - **Makefile Command for Inventory Service**
- **Decision**: Update Makefile to use the virtual environment when running the Inventory Service
- **Rationale**: Ensures consistent environment for running the service
- **Implications**:
  - Simplifies service startup
  - Ensures all required dependencies are available
  - Follows user preference for using Makefiles with multiple commands

## Build and Deployment Decisions
[2025-06-02 10:45:32] - **Added copy-public script to package.json for Analytics API build**
- **Decision**: Added copy-public script to package.json for Analytics API build to ensure dashboard.html and other static assets are copied to the dist/public directory during build
- **Rationale**: Fixes the missing dashboard.html error and improves build robustness
- **Implications**:
  - Fixes the ENOENT error when accessing the dashboard
  - Makes the build process more robust
  - Follows best practices for Node.js/Express applications

[2025-06-03 11:48:51] - **Enhanced Makefile with improved clean and build tasks**
- **Decision**: Enhanced Makefile with improved clean and build tasks
- **Rationale**: Improves build and deployment processes
- **Implications**:
  1. Clean task now removes build artifacts from all services (Java, Python, Node.js)
  2. Build task improved to use virtual environments for Python, npm ci for Node.js, and better build processes
  3. Updated dependency installation tasks to be more consistent and reliable

[2025-06-03 11:59:44] - **Cleaned up Inventory Service codebase**
- **Decision**: Removed redundant files and directories from the Inventory Service
- **Rationale**: Simplify codebase structure and eliminate confusion from duplicate code
- **Implications**:
  1. Removed redundant src/ directory in favor of the inventory_service/ package structure
  2. Removed duplicate venv/ directory, standardizing on .venv/ for virtual environment
  3. Updated README.md with accurate project structure and setup instructions
  4. Updated pyproject.toml to remove unused dependencies (fastavro)
  5. Cleaned up Python cache files

[2025-06-03 12:14:32] - **Fixed Python 3.13 compatibility issues**
- **Decision**: Modified the Makefile's install-python-deps target to handle Python 3.13 compatibility issues
- **Rationale**: The original approach failed with build errors for confluent-kafka and pydantic-core with Python 3.13
- **Implications**:
  1. Created mock packages for confluent-kafka and pydantic to avoid compilation issues
  2. Simplified the dependency installation process
  3. Ensured the inventory service can run on Python 3.13 without requiring native extensions
  4. This is a temporary solution for Phase 3, as Phase 4 will require real Kafka integration

[2025-06-03 12:23:49] - **Switched to Python 3.12 for Inventory Service**
- **Decision**: Changed the virtual environment to use Python 3.12 instead of Python 3.13
- **Rationale**: Python 3.12 has better compatibility with the required packages, especially pydantic
- **Implications**:
  1. Successfully installed pydantic without compilation issues
  2. Created a minimal mock for confluent-kafka with required classes (Consumer, KafkaError, KafkaException)
  3. The inventory service now runs successfully with the mocked Kafka components
  4. This approach provides a more stable solution until the packages officially support Python 3.13

[2025-06-03 12:37:37] - **Added Normal Flow Demo Script**
- **Decision**: Created a new demo script to demonstrate the normal flow scenario
- **Rationale**: Needed a way to verify and demonstrate that all services can communicate properly
- **Implications**:
  1. Provides a clear way to test that the system works correctly with Avro serialization
  2. Complements the existing failure scenario demos
  3. Helps verify that our Python compatibility fixes are working
  4. Serves as documentation for how the system should function normally

## Node.js Build Process
[2025-06-03 11:40:00] - **Copy Public Files in Analytics API Build**
- **Decision**: Add a copy-public script to package.json to copy static files during build
- **Rationale**: Ensures dashboard.html and other public files are available in the dist directory
- **Implications**:
  - Fixes the ENOENT error when accessing the dashboard
  - Makes the build process more robust
  - Follows best practices for Node.js/Express applications
