# A Declarative Grammar for Health Economic Models

![Work In Progress](https://img.shields.io/badge/Status-Work%20In%20Progress-red)
> This package is currently a prototype. Contributions and integration with wider HTA standards are welcome.

JSON model input declaration,
like e.g. the [vega-lite](https://vega.github.io/vega-lite/) syntax.

### Web-tool schema builder

An easy-to-use web interface guides the user in building the model schema and automatically creates the corresponding JSON file to be exported.

Available [here](https://huggingface.co/spaces/n8thangreen/cea-model-builder).

### Example

```json
{
  "$schema": "https://example.com/schema/cea-model-v1.json",
  "metadata": {
    "title": "Cost-Effectiveness of NewDrug vs. Standard Care for Disease X",
    "model_id": "CEA-Project-001",
    "analyst": "J. Doe",
    "currency": "USD",
    "currency_year": 2024
  },
  "analysis_setup": {
    "type": "Markov",
    "time_horizon": 20,
    "time_unit": "years",
    "cycle_length": 1,
    "analysis_perspective": "Healthcare Payer",
    "discount_rates": {
      "costs": 0.03,
      "outcomes": 0.03
    }
  }
}
{
  "comparators": [
    { "id": "soc", "name": "Standard of Care" },
    { "id": "new_drug", "name": "NewDrug" }
  ],
  "states": [
    { "id": "healthy", "name": "Healthy", "initial_proportion": 1.0 },
    { "id": "sick", "name": "Sick", "initial_proportion": 0.0 },
    { "id": "dead", "name": "Dead", "initial_proportion": 0.0 }
  ]
}
{
  "parameters": [
    {
      "id": "p_healthy_to_sick",
      "description": "Annual probability of moving from Healthy to Sick",
      "type": "probability",
      "base_case": 0.1,
      "distribution": {
        "type": "beta",
        "mean": 0.1,
        "se": 0.015
      },
      "data_source": {
      "citation_full": "Smith J, Doe A. (2023). Progression of Disease X. J Health Econ. 1(2):45-56."
     }
      "sensitivity_range": [0.05, 0.15]
    },
    {
      "id": "c_drug_new",
      "description": "Annual cost of NewDrug",
      "type": "cost",
      "currency": "GBP",
      "year": 2025,
      "base_case": 2500,
      "distribution": {
        "type": "gamma",
        "mean": 2500,
        "se": 150
      },
      "data_source": {
        "citation_full": "Smith J, Doe A. (2023). Progression of Disease X. J Health Econ. 1(2):45-56."
       }
      "sensitivity_range": [2000, 3000]
    },
    {
      "id": "u_healthy",
      "description": "Utility weight for the Healthy state",
      "type": "utility",
      "base_case": 0.95,
      "distribution": {
        "type": "beta",
        "mean": 0.95,
        "se": 0.02
      },
      "data_source": {
        "citation_full": "Smith J, Doe A. (2023). Progression of Disease X. J Health Econ. 1(2):45-56."
       }
      "sensitivity_range": [0.9, 1.0]
    }
  ]
}
```
## Validating in R

The repository includes an R function `cea_validate_json()` in the `R/` folder to validate that the JSON object is correct for a CEA-Lite JSON model.

## Parsing in R

The repository includes an R function `parse_cea_model()` in the `R/` folder for parsing CEA-Lite JSON model files into R objects.
This would be a step before using it as input to the particular R cost-effectiveness model.

### Requirements

The function requires the `jsonlite` package:

```r
install.packages("jsonlite")
```

### Usage

To use the parser, source the function and call it with the path to your JSON model file:

```r
# Load the function
source("R/parse_cea_model.R")

# Parse a model file
parsed_model <- parse_cea_model("model.json")
```

The function will:
- Parse the JSON file into a structured R list
- Validate that all required top-level keys are present (`metadata`, `analysis_setup`, `comparators`, `states`, `parameters`, `model_logic`)
- Convert JSON arrays of objects (like `parameters`) into R data frames
- Convert other elements (like `metadata`) into named lists

### Accessing Parsed Data

Once parsed, you can access the model components:

```r
# Access metadata
print(parsed_model$metadata$title)

# Access analysis setup
print(paste("Time Horizon:", parsed_model$analysis_setup$time_horizon, "years"))

# Access parameters as a data frame
print(parsed_model$parameters)

# Access a specific parameter's base case value
p_value <- parsed_model$parameters[parsed_model$parameters$id == "p_healthy_to_sick", "base_case"]
print(paste("Base case for p_healthy_to_sick:", p_value))

# Access states
print(parsed_model$states)

# Access model logic
print(parsed_model$model_logic$transition_matrices)
```

See `scripts/example-parse.R` for a complete working example.
