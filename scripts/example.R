#

library(jsonlite)


# 1. Parse the model
parsed_model <- parse_cea_model("model.json")

print(str(parsed_model, max.level = 2))

# Access setup information
print(paste("Time Horizon:", parsed_model$analysis_setup$time_horizon, "years"))

# Access the parameters
print(parsed_model$parameters)

# Access a specific parameter's base case value
print(paste("Base case for p_healthy_to_sick:", 
            parsed_model$parameters[parsed_model$parameters$id == "p_healthy_to_sick", "base_case"]))
