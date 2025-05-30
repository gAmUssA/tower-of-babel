#!/usr/bin/env python3
"""
Generate Python dataclasses from Avro schemas.
This script reads Avro schema files and generates Python dataclasses.
"""

import json
import os
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

# Schema type mapping from Avro to Python
TYPE_MAPPING = {
    "string": "str",
    "int": "int",
    "long": "int",
    "float": "float",
    "double": "float",
    "boolean": "bool",
    "bytes": "bytes",
    "null": "None",
}


def avro_to_python_type(avro_type: Any) -> str:
    """Convert Avro type to Python type."""
    if isinstance(avro_type, str):
        return TYPE_MAPPING.get(avro_type, avro_type)
    elif isinstance(avro_type, list):
        # Handle union types
        if "null" in avro_type:
            # If null is in the union, make the type Optional
            non_null_types = [t for t in avro_type if t != "null"]
            if len(non_null_types) == 1:
                return f"Optional[{avro_to_python_type(non_null_types[0])}]"
            else:
                types = ", ".join(avro_to_python_type(t) for t in non_null_types)
                return f"Optional[Union[{types}]]"
        else:
            types = ", ".join(avro_to_python_type(t) for t in avro_type)
            return f"Union[{types}]"
    elif isinstance(avro_type, dict):
        # Handle complex types
        if avro_type.get("type") == "array":
            item_type = avro_to_python_type(avro_type.get("items"))
            return f"List[{item_type}]"
        elif avro_type.get("type") == "map":
            value_type = avro_to_python_type(avro_type.get("values"))
            return f"Dict[str, {value_type}]"
        elif avro_type.get("type") == "record":
            # For nested records, just use the name
            return avro_type.get("name")
    return "Any"  # Default to Any for unknown types


def generate_dataclass(schema: Dict[str, Any], output_dir: Path) -> None:
    """Generate a Python dataclass from an Avro schema."""
    record_name = schema.get("name")
    namespace = schema.get("namespace", "").replace(".", "_")
    fields = schema.get("fields", [])
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Determine output file path
    if namespace:
        output_file = output_dir / f"{namespace}_{record_name}.py"
    else:
        output_file = output_dir / f"{record_name}.py"
    
    # Generate imports
    imports = [
        "from dataclasses import dataclass, field",
        "from typing import Any, Dict, List, Optional, Union",
    ]
    
    # Generate class definition
    class_def = [
        f"@dataclass",
        f"class {record_name}:",
        f'    """',
        f"    {schema.get('doc', 'Generated from Avro schema')}",
        f'    """',
    ]
    
    # Generate field definitions
    for field_def in fields:
        field_name = field_def.get("name")
        field_type = avro_to_python_type(field_def.get("type"))
        field_doc = field_def.get("doc", "")
        
        # Handle default values
        if "default" in field_def:
            default_value = field_def.get("default")
            if default_value is None:
                class_def.append(f"    {field_name}: {field_type} = None  # {field_doc}")
            elif isinstance(default_value, str):
                class_def.append(f'    {field_name}: {field_type} = "{default_value}"  # {field_doc}')
            elif isinstance(default_value, (dict, list)):
                class_def.append(f"    {field_name}: {field_type} = field(default_factory=lambda: {default_value})  # {field_doc}")
            else:
                class_def.append(f"    {field_name}: {field_type} = {default_value}  # {field_doc}")
        else:
            class_def.append(f"    {field_name}: {field_type}  # {field_doc}")
    
    # Write to file
    with open(output_file, "w") as f:
        f.write("\n".join(imports) + "\n\n\n")
        f.write("\n".join(class_def) + "\n")
    
    print(f"Generated {output_file}")


def generate_init_file(output_dir: Path) -> None:
    """Generate __init__.py file to make the directory a package."""
    init_file = output_dir / "__init__.py"
    
    # Get all Python files in the directory
    py_files = [f.stem for f in output_dir.glob("*.py") if f.name != "__init__.py"]
    
    # Generate imports
    imports = []
    for py_file in py_files:
        if "_" in py_file:
            namespace, record_name = py_file.rsplit("_", 1)
            imports.append(f"from .{py_file} import {record_name}")
        else:
            imports.append(f"from .{py_file} import {py_file}")
    
    # Write to file
    with open(init_file, "w") as f:
        f.write("\n".join(imports) + "\n")
    
    print(f"Generated {init_file}")


def main():
    """Main function to generate Python dataclasses from Avro schemas."""
    # Define paths
    project_root = Path(__file__).parent.parent.parent.parent
    schema_dir = project_root / "schemas" / "v1"
    output_dir = project_root / "services" / "inventory-service" / "src" / "generated"
    
    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Process each schema file
    for schema_file in schema_dir.glob("*.avsc"):
        print(f"Processing {schema_file}...")
        with open(schema_file, "r") as f:
            schema = json.load(f)
        
        generate_dataclass(schema, output_dir)
    
    # Generate __init__.py
    generate_init_file(output_dir)
    
    print("Code generation complete!")


if __name__ == "__main__":
    main()
