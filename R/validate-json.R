# R Script for Validating Health Economic Analysis (CEA) JSON Input

# This script provides functions to load, validate, and summarize
# a JSON file intended for use with cost-effectiveness analysis (CEA)
# models, specifically against the principles of the 'cea-schema'.

# NOTE: You will need to install the 'jsonlite' and 'jsonvalidate' packages
# if you haven't already:
# install.packages(c("jsonlite", "jsonvalidate"))


# --- 1. Dependencies and Setup ---
library(jsonlite)
library(jsonvalidate)

# --- 2. Define the Expected Schema Structure ---
# For robust validation, we need a formal JSON Schema file.
# Since we don't have the external schema file here, we will define a
# simplified R list structure reflecting the core *required elements*
# of a typical CEA model input (like the CEA-schema expects).
# This provides a basic structural check, ensuring the necessary elements exist.

# A placeholder function representing the expected schema for critical CEA inputs.
# In a real-world scenario, you would load the full, formal JSON schema file.
define_cea_schema_requirements <- function() {
  list(
    # Check for the main strategies array
    strategies = list(
      type = "array",
      items = list(
        type = "object",
        properties = list(
          # Each strategy must have an ID and a name (for documentation/metadata)
          strategy_id = list(type = "integer"),
          strategy_name = list(type = "string"),
          # Must contain cost and effect data
          costs = list(type = "array"),
          effects = list(type = "array")
        ),
        required = c("strategy_id", "strategy_name", "costs", "effects")
      )
    ),
    # Check for parameters, crucial for Probabilistic Sensitivity Analysis (PSA)
    parameters = list(
      type = "object",
      properties = list(
        # Must define the willingness-to-pay threshold (WTP)
        wtp_threshold = list(type = "number")
      ),
      required = "wtp_threshold"
    )
  )
}


# --- 3. Core Validation Function ---

#' Loads and validates a JSON file against CEA structure requirements.
#'
#' This function performs structural checks and basic data integrity checks
#' before the JSON data is passed to a statistical model.
#'
#' @param filepath The path to the input JSON file.
#' @return A list containing the loaded data (if valid) and validation results.
validate_cea_json <- function(filepath) {
  cat(paste("--- Starting Validation for:", filepath, "---\n"))

  # 1. Check File Existence and Readability
  if (!file.exists(filepath)) {
    stop("Error: File not found at the specified path.")
  }

  # 2. Load JSON Data
  tryCatch({
    data <- jsonlite::fromJSON(filepath, simplifyVector = FALSE)
  }, error = function(e) {
    stop(paste("Error: Failed to parse JSON file. Check for formatting errors (commas, quotes). Original error:", e$message))
  })

  # 3. Structural Validation (Data Stewardship Check)
  schema <- define_cea_schema_requirements()
  is_structurally_valid <- jsonvalidate::json_validate(
    jsonlite::toJSON(data, auto_unbox = TRUE),
    jsonlite::toJSON(schema, auto_unbox = TRUE),
    verbose = TRUE,
    engine = "ajv" # Use the Ajv engine for robust schema validation
  )

  results <- list(
    data = data,
    structural_valid = is_structurally_valid,
    messages = attr(is_structurally_valid, "errors")
  )

  if (!is_structurally_valid) {
    cat("Validation FAILED: The JSON file is missing required top-level elements or structures.\n")
    print(results$messages)
    return(results)
  }

  cat("Structural Validation Passed: Required components (strategies, parameters) are present.\n")

  # 4. Perform Data Integrity Checks (Domain-Specific Checks)
  
  # Check 4a: At least two strategies must be present for a comparative CEA
  if (length(data$strategies) < 2) {
    results$integrity_check_1 <- FALSE
    cat("Integrity Check FAILED: CEA requires at least two comparison strategies (found: ", length(data$strategies), ").\n")
  } else {
    results$integrity_check_1 <- TRUE
    cat("Integrity Check Passed: Found ", length(data$strategies), " comparison strategies.\n")
  }

  # Check 4b: Ensure all cost/effect arrays are non-empty
  strategy_names <- sapply(data$strategies, function(s) s$strategy_name)
  all_data_present <- TRUE
  for (i in seq_along(data$strategies)) {
    strategy <- data$strategies[[i]]
    if (length(strategy$costs) == 0 || length(strategy$effects) == 0) {
      cat(paste("Integrity Check FAILED: Strategy '", strategy_names[i], "' has empty costs or effects array.\n", sep=""))
      all_data_present <- FALSE
    }
  }
  results$integrity_check_2 <- all_data_present
  if (all_data_present) {
    cat("Integrity Check Passed: All strategies contain costs and effects data.\n")
  }

  cat("--- Validation Complete ---\n")
  return(results)
}
