---
trigger: glob
globs: **/*.py
---

# Python Testing Standards

## Test Framework Configuration

- Framework: pytest 7.4.4
- Test location: `tests/` directory (separate from package)
- Virtual environment: `.venv` (always activate before testing)

## Running Tests

```bash
cd services/inventory-service
source .venv/bin/activate                  # ALWAYS activate venv first
python -m pytest                           # Run all tests
python -m pytest tests/test_utils.py       # Run specific file
python -m pytest -v                        # Verbose output
python -m pytest -k "test_name"            # Run tests matching pattern
python -m pytest --cov                     # With coverage
```

## Test Structure Pattern

Use class-based organization with descriptive docstrings:

```python
import pytest
from inventory_service.utils import validate_order_data

class TestValidateOrderData:
    """Tests for validate_order_data function"""
    
    def test_valid_order_data(self):
        """Test validation with all required fields"""
        order_data = {
            'orderId': '123',
            'userId': 'user456',
            'amount': 99.99,
            'status': 'PENDING'
        }
        assert validate_order_data(order_data) is True
    
    def test_missing_required_field(self):
        """Test validation with missing required field"""
        order_data = {'orderId': '123', 'userId': 'user456'}
        assert validate_order_data(order_data) is False
```

## Virtual Environment Setup

ALWAYS use virtual environment:

```bash
cd services/inventory-service
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Kafka Consumer Testing

Use pytest-kafka for Kafka testing:

```python
@pytest.fixture
def kafka_consumer():
    consumer = KafkaConsumer(...)
    yield consumer
    consumer.close()

def test_consume_order_event(kafka_consumer):
    # Test implementation
    pass
```

## Test File Naming

MUST follow pytest discovery patterns:
- Files: `test_*.py` or `*_test.py`
- Functions: `test_*`
- Classes: `Test*`

## Code Style

- Follow PEP 8 style guide
- Use type hints for function signatures
- Google-style docstrings for public functions
- Black for formatting (line length: 100)

## NEVER

- Run tests without activating virtual environment
- Import from generated/ directory in production code
- Use blocking Kafka clients in async FastAPI routes
- Skip cleanup in test teardown