def validate_schema_function(input_text: str) -> str:
    if "database" in input_text.lower():
        return "Schema validated."
    return "Invalid or incomplete schema."
