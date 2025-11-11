
library(shiny)
library(DT)
library(shinyjs)
library(jsonlite)
library(shinyWidgets)

# --- Helper function to create the parameter modal UI ---
# This creates the form for adding/editing a parameter
param_modal_ui <- function(param = NULL) {
  
  # Set default values if not editing
  if (is.null(param)) {
    param <- list(
      id = "", description = "", type = "probability", base_case = 0,
      distribution = list(type = "beta", mean = 0, se = 0)
    )
  }
  
  # Re-structure distribution for UI
  dist_type <- param$distribution$type
  dist_p1_val <- NA
  dist_p2_val <- NA
  
  if (dist_type == "beta") {
    dist_p1_val <- param$distribution$mean
    dist_p2_val <- param$distribution$se
  } else if (dist_type == "gamma") {
    dist_p1_val <- param$distribution$mean
    dist_p2_val <- param$distribution$se
  } else if (dist_type == "lognormal") {
    dist_p1_val <- param$distribution$meanlog
    dist_p2_val <- param$distribution$sdlog
  }
  
  modalDialog(
    title = if (is.null(param$id) || param$id == "") "Add New Parameter" else "Edit Parameter",
    useShinyjs(),
    textInput("param_id", "Parameter ID (short name)", value = param$id),
    textAreaInput("param_description", "Description", value = param$description),
    fluidRow(
      column(6, selectInput("param_type", "Parameter Type",
                            choices = c("probability", "cost", "utility", "relative_risk", "rate", "other"),
                            selected = param$type)),
      column(6, numericInput("param_base_case", "Base Case Value", value = param$base_case, step = 0.01))
    ),
    h4("Uncertainty Distribution"),
    selectInput("param_dist_type", "Distribution Type",
                choices = c("beta", "gamma", "lognormal", "fixed", "normal", "uniform"),
                selected = dist_type),
    
    # Dynamic UI for distribution parameters
    uiOutput("dist_params_ui"),
    
    # Hidden inputs to pass values (pre-filled by observer)
    hidden(
      numericInput("dist_p1_val_hidden", "p1", value = dist_p1_val),
      numericInput("dist_p2_val_hidden", "p2", value = dist_p2_val)
    ),
    
    footer = tagList(
      modalButton("Cancel"),
      actionButton("save_param", "Save")
    )
  )
}


# --- UI Definition ---
ui <- fluidPage(
  useShinyjs(), # Enable shinyjs
  titlePanel("CEA-Lite Model Specification Builder"),
  
  tabsetPanel(
    id = "main_tabs",
    
    # --- 1. METADATA ---
    tabPanel("1. Metadata",
             icon = icon("book"),
             sidebarLayout(
               sidebarPanel(
                 h4("Project Information"),
                 "Define the high-level details of your analysis."
               ),
               mainPanel(
                 br(),
                 textInput("meta_title", "Model Title", "Cost-Effectiveness of..."),
                 textInput("meta_model_id", "Model ID", "CEA-Project-001"),
                 textInput("meta_analyst", "Analyst Name", "J. Doe"),
                 fluidRow(
                   column(6, textInput("meta_currency", "Currency", "USD")),
                   column(6, numericInput("meta_currency_year", "Currency Year", 2024, min = 1970, max = 2100))
                 )
               )
             )
    ),
    
    # --- 2. ANALYSIS SETUP ---
    tabPanel("2. Analysis Setup",
             icon = icon("cogs"),
             sidebarLayout(
               sidebarPanel(
                 h4("Model Structure"),
                 "Define the core assumptions for the simulation."
               ),
               mainPanel(
                 br(),
                 selectInput("setup_type", "Model Type", choices = c("Markov", "Partitioned Survival", "DES", "Other"), selected = "Markov"),
                 selectInput("setup_perspective", "Analysis Perspective", choices = c("Healthcare Payer", "Societal", "Provider"), selected = "Healthcare Payer"),
                 fluidRow(
                   column(4, numericInput("setup_horizon", "Time Horizon", 20)),
                   column(4, selectInput("setup_time_unit", "Time Unit", choices = c("years", "months", "weeks", "days"), selected = "years")),
                   column(4, numericInput("setup_cycle_length", "Cycle Length (in Time Unit)", 1))
                 ),
                 h5("Discount Rates"),
                 fluidRow(
                   column(6, numericInput("setup_discount_costs", "Discount Rate (Costs)", 0.03, min = 0, max = 1, step = 0.005)),
                   column(6, numericInput("setup_discount_outcomes", "Discount Rate (Outcomes)", 0.03, min = 0, max = 1, step = 0.005))
                 )
               )
             )
    ),
    
    # --- 3. COMPARATORS ---
    tabPanel("3. Comparators",
             icon = icon("balance-scale"),
             sidebarLayout(
               sidebarPanel(
                 h4("Strategies"),
                 "Define the interventions or strategies being compared.",
                 br(),
                 actionButton("add_comp", "Add Comparator", icon = icon("plus"), class = "btn-primary"),
                 actionButton("edit_comp", "Edit Selected", icon = icon("edit")),
                 actionButton("delete_comp", "Delete Selected", icon = icon("trash-alt"), class = "btn-danger")
               ),
               mainPanel(
                 br(),
                 DTOutput("comparators_table")
               )
             )
    ),
    
    # --- 4. STATES ---
    tabPanel("4. Health States",
             icon = icon("heartbeat"),
             sidebarLayout(
               sidebarPanel(
                 h4("Health States"),
                 "Define the health states for the model (e.g., Markov states).",
                 br(),
                 actionButton("add_state", "Add State", icon = icon("plus"), class = "btn-primary"),
                 actionButton("edit_state", "Edit Selected", icon = icon("edit")),
                 actionButton("delete_state", "Delete Selected", icon = icon("trash-alt"), class = "btn-danger")
               ),
               mainPanel(
                 br(),
                 DTOutput("states_table")
               )
             )
    ),
    
    # --- 5. PARAMETERS ---
    tabPanel("5. Parameters",
             icon = icon("list-ol"),
             sidebarLayout(
               sidebarPanel(
                 h4("Model Parameters"),
                 "Define all model inputs (costs, utilities, probabilities).",
                 br(),
                 actionButton("add_param", "Add Parameter", icon = icon("plus"), class = "btn-primary"),
                 actionButton("edit_param", "Edit Selected", icon = icon("edit")),
                 actionButton("delete_param", "Delete Selected", icon = icon("trash-alt"), class = "btn-danger")
               ),
               mainPanel(
                 br(),
                 DTOutput("parameters_table")
               )
             )
    ),
    
    # --- 6. MODEL LOGIC ---
    tabPanel("6. Model Logic (Placeholder)",
             icon = icon("project-diagram"),
             sidebarLayout(
               sidebarPanel(
                 h4("Model Logic"),
                 "This section is a placeholder for defining the logic, such as transition matrices.",
                 "A full UI for this is complex. For now, you can paste text/JSON snippets."
               ),
               mainPanel(
                 br(),
                 textAreaInput("logic_placeholder", "Model Logic Snippets", 
                               placeholder = "Example: \n[\n  ['1 - p_sick - p_dead', 'p_sick', 'p_dead'], ...\n]",
                               height = "300px")
               )
             )
    ),
    
    # --- 7. EXPORT ---
    tabPanel("7. Export Model",
             icon = icon("download"),
             fluidRow(
               column(6,
                      h3("Download Model"),
                      p("Click to download the complete model specification as a JSON file."),
                      downloadButton("download_json", "Download model.json", class = "btn-success")
               ),
               column(6,
                      h3("Live JSON Preview"),
                      verbatimTextOutput("json_preview")
               )
             )
    )
  )
)


# --- SERVER Logic ---
server <- function(input, output, session) {
  
  # --- Reactive Values Store ---
  rv <- reactiveValues(
    comparators = data.frame(id = c("soc", "new_drug"), 
                             name = c("Standard of Care", "New Drug"),
                             stringsAsFactors = FALSE),
    states = data.frame(id = c("healthy", "sick", "dead"),
                        name = c("Healthy", "Sick", "Dead"),
                        initial_proportion = c(1.0, 0.0, 0.0),
                        stringsAsFactors = FALSE),
    parameters = list(
      list(id = "p_healthy_to_sick", description = "Annual prob. of getting sick", type = "probability", base_case = 0.1,
           distribution = list(type = "beta", mean = 0.1, se = 0.015)),
      list(id = "c_drug_new", description = "Annual cost of NewDrug", type = "cost", base_case = 2500,
           distribution = list(type = "gamma", mean = 2500, se = 150)),
      list(id = "u_healthy", description = "Utility for Healthy state", type = "utility", base_case = 0.95,
           distribution = list(type = "beta", mean = 0.95, se = 0.02))
    ),
    # Keep track of which row is being edited
    edit_row_index = NULL,
    edit_mode = "add"
  )
  
  
  # --- 3. COMPARATORS Logic ---
  output$comparators_table <- renderDT({
    datatable(rv$comparators, selection = 'single', rownames = FALSE,
              options = list(dom = 't', pageLength = -1))
  })
  
  # ADD Comparator
  observeEvent(input$add_comp, {
    rv$edit_mode <- "add"
    showModal(modalDialog(
      title = "Add New Comparator",
      textInput("comp_id", "Comparator ID (e.g., 'soc')", ""),
      textInput("comp_name", "Comparator Name (e.g., 'Standard of Care')", ""),
      footer = tagList(modalButton("Cancel"), actionButton("save_comp", "Save"))
    ))
  })
  
  # EDIT Comparator
  observeEvent(input$edit_comp, {
    s <- input$comparators_table_rows_selected
    if (length(s)) {
      rv$edit_mode <- "edit"
      rv$edit_row_index <- s
      
      item <- rv$comparators[s, ]
      
      showModal(modalDialog(
        title = "Edit Comparator",
        textInput("comp_id", "Comparator ID", value = item$id),
        textInput("comp_name", "Comparator Name", value = item$name),
        footer = tagList(modalButton("Cancel"), actionButton("save_comp", "Save"))
      ))
    } else {
      showNotification("Please select a row to edit.", type = "warning")
    }
  })
  
  # SAVE Comparator (Add or Edit)
  observeEvent(input$save_comp, {
    removeModal()
    new_item <- data.frame(id = input$comp_id, name = input$comp_name, stringsAsFactors = FALSE)
    
    if (rv$edit_mode == "add") {
      rv$comparators <- rbind(rv$comparators, new_item)
    } else {
      rv$comparators[rv$edit_row_index, ] <- new_item
    }
  })
  
  # DELETE Comparator
  observeEvent(input$delete_comp, {
    s <- input$comparators_table_rows_selected
    if (length(s)) {
      rv$comparators <- rv$comparators[-s, , drop = FALSE]
    } else {
      showNotification("Please select a row to delete.", type = "warning")
    }
  })
  
  
  # --- 4. STATES Logic ---
  output$states_table <- renderDT({
    datatable(rv$states, selection = 'single', rownames = FALSE,
              options = list(dom = 't', pageLength = -1))
  })
  
  # ADD State
  observeEvent(input$add_state, {
    rv$edit_mode <- "add"
    showModal(modalDialog(
      title = "Add New State",
      textInput("state_id", "State ID (e.g., 'healthy')", ""),
      textInput("state_name", "State Name (e.g., 'Healthy')", ""),
      numericInput("state_initial_prop", "Initial Proportion", 0.0, min = 0, max = 1, step = 0.01),
      footer = tagList(modalButton("Cancel"), actionButton("save_state", "Save"))
    ))
  })
  
  # EDIT State
  observeEvent(input$edit_state, {
    s <- input$states_table_rows_selected
    if (length(s)) {
      rv$edit_mode <- "edit"
      rv$edit_row_index <- s
      
      item <- rv$states[s, ]
      
      showModal(modalDialog(
        title = "Edit State",
        textInput("state_id", "State ID", value = item$id),
        textInput("state_name", "State Name", value = item$name),
        numericInput("state_initial_prop", "Initial Proportion", value = item$initial_proportion, min = 0, max = 1, step = 0.01),
        footer = tagList(modalButton("Cancel"), actionButton("save_state", "Save"))
      ))
    } else {
      showNotification("Please select a row to edit.", type = "warning")
    }
  })
  
  # SAVE State (Add or Edit)
  observeEvent(input$save_state, {
    removeModal()
    new_item <- data.frame(id = input$state_id, 
                           name = input$state_name, 
                           initial_proportion = input$state_initial_prop,
                           stringsAsFactors = FALSE)
    
    if (rv$edit_mode == "add") {
      rv$states <- rbind(rv$states, new_item)
    } else {
      rv$states[rv$edit_row_index, ] <- new_item
    }
  })
  
  # DELETE State
  observeEvent(input$delete_state, {
    s <- input$states_table_rows_selected
    if (length(s)) {
      rv$states <- rv$states[-s, , drop = FALSE]
    } else {
      showNotification("Please select a row to delete.", type = "warning")
    }
  })
  
  
  # --- 5. PARAMETERS Logic ---
  
  # Flatten parameter list for display in DT
  flat_params <- reactive({
    do.call(rbind, lapply(rv$parameters, function(p) {
      data.frame(
        id = p$id,
        description = p$description,
        type = p$type,
        base_case = p$base_case,
        distribution = p$distribution$type,
        stringsAsFactors = FALSE
      )
    }))
  })
  
  output$parameters_table <- renderDT({
    datatable(flat_params(), selection = 'single', rownames = FALSE,
              options = list(dom = 't', pageLength = -1))
  })
  
  # ADD Parameter
  observeEvent(input$add_param, {
    rv$edit_mode <- "add"
    showModal(param_modal_ui(NULL))
  })
  
  # EDIT Parameter
  observeEvent(input$edit_param, {
    s <- input$parameters_table_rows_selected
    if (length(s)) {
      rv$edit_mode <- "edit"
      rv$edit_row_index <- s
      
      item <- rv$parameters[[s]]
      showModal(param_modal_ui(item))
      
    } else {
      showNotification("Please select a row to edit.", type = "warning")
    }
  })
  
  # DYNAMIC UI for distribution parameters
  output$dist_params_ui <- renderUI({
    dist_type <- input$param_dist_type
    
    # Get pre-filled values if in "edit" mode
    p1_val <- input$dist_p1_val_hidden
    p2_val <- input$dist_p2_val_hidden
    
    if (is.null(dist_type)) return(NULL)
    
    if (dist_type == "beta") {
      tagList(
        numericInput("dist_p1", "Mean", value = p1_val),
        numericInput("dist_p2", "Std. Error (SE)", value = p2_val)
      )
    } else if (dist_type == "gamma") {
      tagList(
        numericInput("dist_p1", "Mean", value = p1_val),
        numericInput("dist_p2", "Std. Error (SE)", value = p2_val)
      )
    } else if (dist_type == "lognormal") {
      tagList(
        numericInput("dist_p1", "Mean (on log scale)", value = p1_val),
        numericInput("dist_p2", "SD (on log scale)", value = p2_val)
      )
    } else if (dist_type == "normal") {
      tagList(
        numericInput("dist_p1", "Mean", value = p1_val),
        numericInput("dist_p2", "Std. Dev (SD)", value = p2_val)
      )
    } else if (dist_type == "uniform") {
      tagList(
        numericInput("dist_p1", "Min", value = p1_val),
        numericInput("dist_p2", "Max", value = p2_val)
      )
    } else if (dist_type == "fixed") {
      p("No uncertainty parameters needed for 'fixed'.")
    }
  })
  
  
  # SAVE Parameter (Add or Edit)
  observeEvent(input$save_param, {
    removeModal()
    
    # Build the nested distribution list
    dist_list <- list(type = input$param_dist_type)
    if (input$param_dist_type == "beta") {
      dist_list$mean <- input$dist_p1
      dist_list$se <- input$dist_p2
    } else if (input$param_dist_type == "gamma") {
      dist_list$mean <- input$dist_p1
      dist_list$se <- input$dist_p2
    } else if (input$param_dist_type == "lognormal") {
      dist_list$meanlog <- input$dist_p1
      dist_list$sdlog <- input$dist_p2
    } else if (input$param_dist_type == "normal") {
      dist_list$mean <- input$dist_p1
      dist_list$sd <- input$dist_p2
    } else if (input$param_dist_type == "uniform") {
      dist_list$min <- input$dist_p1
      dist_list$max <- input$dist_p2
    }
    
    # Create the full parameter item
    new_item <- list(
      id = input$param_id,
      description = input$param_description,
      type = input$param_type,
      base_case = input$param_base_case,
      distribution = dist_list
    )
    
    if (rv$edit_mode == "add") {
      rv$parameters[[length(rv$parameters) + 1]] <- new_item
    } else {
      rv$parameters[[rv$edit_row_index]] <- new_item
    }
  })
  
  # DELETE Parameter
  observeEvent(input$delete_param, {
    s <- input$parameters_table_rows_selected
    if (length(s)) {
      rv$parameters[[s]] <- NULL # Remove list item by setting to NULL
    } else {
      showNotification("Please select a row to delete.", type = "warning")
    }
  })
  
  
  # --- 7. EXPORT Logic ---
  
  # Reactive expression to build the final list
  final_model_list <- reactive({
    list(
      `$schema` = "https://example.com/schema/cea-model-v1.json",
      metadata = list(
        title = input$meta_title,
        model_id = input$meta_model_id,
        analyst = input$meta_analyst,
        currency = input$meta_currency,
        currency_year = input$meta_currency_year
      ),
      analysis_setup = list(
        type = input$setup_type,
        time_horizon = input$setup_horizon,
        time_unit = input$setup_time_unit,
        cycle_length = input$setup_cycle_length,
        analysis_perspective = input$setup_perspective,
        discount_rates = list(
          costs = input$setup_discount_costs,
          outcomes = input$setup_discount_outcomes
        )
      ),
      comparators = rv$comparators,
      states = rv$states,
      parameters = rv$parameters,
      model_logic = list(
        placeholder = input$logic_placeholder
      )
    )
  })
  
  # JSON Preview
  output$json_preview <- renderText({
    jsonlite::toJSON(final_model_list(), pretty = TRUE, auto_unbox = TRUE)
  })
  
  # Download Handler
  output$download_json <- downloadHandler(
    filename = function() {
      "model_specification.json"
    },
    content = function(file) {
      json_data <- jsonlite::toJSON(final_model_list(), pretty = TRUE, auto_unbox = TRUE)
      writeLines(json_data, file)
    }
  )
  
}

# Run the application
shiny::shinyApp(ui = ui, server = server)
