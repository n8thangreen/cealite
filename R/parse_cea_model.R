
#' Parses a "CEA-Lite" JSON model file into an R list
#'
#' @param filepath The path to the .json model file.
#' @return A nested R list containing the model specification.
#'
parse_cea_model <- function(filepath) {
  
  message("Parsing model file: ", filepath)
  
  # The "parser" is the fromJSON function.
  # It intelligently converts the JSON arrays of objects
  # (like 'parameters') into R data frames.
  # Other things (like 'metadata') become named lists.
  # `simplifyDataFrame = TRUE` is the default and is what we want.
  model_spec <- tryCatch({
    jsonlite::fromJSON(filepath, simplifyDataFrame = TRUE)
  }, error = function(e) {
    stop("Failed to parse JSON. Error: ", e$message)
  })
  
  # --- Basic Validation ---
  # A robust parser would validate this against a formal schema,
  # but for now, we'll just check for the main keys.
  required_keys <- c("metadata", "analysis_setup", "comparators", 
                     "states", "parameters", "model_logic")
  
  if (!all(required_keys %in% names(model_spec))) {
    stop("Invalid model file: Missing one or more required top-level keys.")
  }
  
  message("Successfully parsed model: ", model_spec$metadata$title)
  return(model_spec)
}

