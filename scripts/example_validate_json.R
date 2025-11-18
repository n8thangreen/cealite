
# --- 4. Example Usage and Data Simulation ---

# Create a sample invalid JSON file for testing
example_invalid_json <- '{
  "parameters": {
    "wtp_threshold": 30000
    // Strategies are intentionally missing here to trigger a validation error
  },
  "some_other_data": "metadata"
}'
writeLines(example_invalid_json, "invalid_cea_input.json")


# Create a sample valid JSON file for testing
example_valid_json <- '{
  "parameters": {
    "wtp_threshold": 25000
  },
  "strategies": [
    {
      "strategy_id": 1,
      "strategy_name": "Standard Care",
      "costs": [10000, 10500, 9800],
      "effects": [0.75, 0.74, 0.76]
    },
    {
      "strategy_id": 2,
      "strategy_name": "New Intervention",
      "costs": [15000, 14900, 16000],
      "effects": [0.85, 0.86, 0.84]
    }
  ]
}'
writeLines(example_valid_json, "valid_cea_input.json")


# --- RUN EXAMPLES ---

# 1. Test with the valid JSON file
cat("\n\n################################\n")
cat("# Running Test 1: Valid JSON\n")
cat("################################\n")
valid_results <- validate_cea_json("valid_cea_input.json")
# You can now access the validated data: valid_results$data


# 2. Test with the invalid JSON file (missing strategies)
cat("\n\n################################\n")
cat("# Running Test 2: Invalid JSON (structural error)\n")
cat("################################\n")
invalid_results <- validate_cea_json("invalid_cea_input.json")
# If the file is structurally invalid, the 'data' element might be incomplete or missing key components.
