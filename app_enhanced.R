# Enhanced ARTEMIS Metadata Collection App with Comprehensive Preload Functionality
# This example demonstrates the full preload capabilities

library(shiny)
library(jsonlite)
library(bslib)
library(shinyalert)
library(readxl)
library(DT)
library(shinyjs)
library(dplyr)
library(knitr)
library(stringr)
library(shinyBS)
library(hover)
library(shinyFeedback)
library(shinyWidgets)
library(ggplot2)
library(plotly)
library(pheatmap)
library(ggsci)
library(plotly)
library(ggrepel)
library(tidyr)
library(sortable)

# Source the enhanced components
source("R/meta_ui_enhanced.R")
source("R/meta_server_enhanced.R")

# Mock ontology functions for demonstration
search_centree_ontology_by_term <- function(token, term, ontology_id) {
  # Mock function - in real implementation this would call the actual API
  return(list(
    results = list(
      list(id = "mock_1", name = paste("Mock result for", term), description = "Mock description")
    )
  ))
}

extract_ontology_with_description <- function(results) {
  # Mock function - in real implementation this would extract from API results
  if (is.null(results) || length(results) == 0) {
    return(character(0))
  }
  return(c("Mock Option 1" = "mock_1", "Mock Option 2" = "mock_2"))
}

extract_ontology_without_description <- function(results) {
  # Mock function - in real implementation this would extract from API results
  if (is.null(results) || length(results) == 0) {
    return(character(0))
  }
  return(c("Mock Option 1", "Mock Option 2"))
}

# Read environment variables (mock for demonstration)
readRenviron(".Renviron")

ui <- fluidPage(
  title = "Enhanced ARTEMIS Metadata Collection",
  
  # Header with preload information
  div(
    style = "background-color: #f8f9fa; padding: 15px; margin-bottom: 20px; border-radius: 5px;",
    h3("Enhanced ARTEMIS Metadata Collection", style = "margin-top: 0;"),
    p("This enhanced version supports comprehensive metadata preloading to reduce re-entry friction."),
    
    # Preload demonstration buttons
    div(
      style = "margin-top: 15px;",
      h5("Demonstration Options:"),
      actionButton("demo_basic", "Demo: Basic Preload", class = "btn btn-primary", style = "margin-right: 10px;"),
      actionButton("demo_comprehensive", "Demo: Comprehensive Preload", class = "btn btn-success", style = "margin-right: 10px;"),
      actionButton("demo_partial", "Demo: Partial Preload", class = "btn btn-warning", style = "margin-right: 10px;"),
      actionButton("reset_demo", "Reset Demo", class = "btn btn-secondary")
    )
  ),
  
  # Main metadata UI
  metaDataUI("metaDataCollector", tool = "Artemis", runsStandlone = TRUE),
  
  # Debug information panel (for demonstration)
  div(
    style = "margin-top: 30px; padding: 15px; background-color: #f8f9fa; border-radius: 5px;",
    h4("Debug Information (Development Only)"),
    verbatimTextOutput("debug_info"),
    
    h5("Current Metadata State:"),
    verbatimTextOutput("current_state"),
    
    h5("Preload Validation:"),
    verbatimTextOutput("preload_validation")
  )
)

server <- function(input, output, session) {
  
  # Reactive value to store current preload configuration
  current_preload <- reactiveVal(NULL)
  
  # Example preload configurations
  basic_preload <- list(
    study_name = "HMC3 treated with Neurotransmitter",
    therapeutic_area = "NEU",
    species = "Homo sapiens",
    main_comparison = "Treatment",
    token_ct = "mock_token_123",
    analyst = "timo.lange@abbvie.com",
    number_of_samples = 5
  )
  
  comprehensive_preload <- list(
    # Basic fields
    study_name = "Comprehensive Study Example",
    therapeutic_area = "Neuroscience",
    species = "Homo sapiens",
    main_comparison = "Gene Modulation vs Control",
    token_ct = "comprehensive_token_456",
    analyst = "researcher@abbvie.com",
    number_of_samples = 24,
    
    # UI state fields
    category_selection = "Disease indication",
    main_question = "Changes introduced by gene modulation",
    trait_type_selection = "Gene impact",
    experiment_type = "in vitro",
    data_source = "Internal",
    effect_type = "knock out",
    target_known = "target known",
    effect_known = "Yes",
    is_ipsc_derived = TRUE,
    
    # Detailed metadata
    trait_details = "CRISPR-mediated knockout of target gene",
    strain = "C57BL/6J",
    data_generated_by = "Lab Technician A",
    data_source_link = "",
    cell_info_2 = c("BMWi iNGN2_telencephalic", "dSMADi_cortical excitatory"),
    
    # CDM metadata
    CDM_meta = list(
      trait = "APOE knockout",
      trait_type = "Gene impact",
      trait_details = "Complete knockout using CRISPR/Cas9",
      disease = "Alzheimer's Disease",
      pheno = NULL,
      therapeutic = "Neuroscience",
      cell = "Neuron",
      line = "iPSC-derived",
      tissue = "Brain tissue",
      platform_instrument = "10X Genomics",
      strain = "C57BL/6J",
      protocol = "BMWi differentiation protocol"
    ),
    
    # Multiple selections
    multiple_gene = c("APOE", "TREM2"),
    multiple_cell = c("Neuron", "Microglia"),
    multiple_disease = c("Alzheimer's Disease"),
    
    # Confirmation states
    user_confirmation = TRUE,
    user_confirmation_2nd_layer = TRUE,
    user_confirmation_3rd_layer = TRUE,
    user_confirmation_4th_layer = FALSE
  )
  
  partial_preload <- list(
    study_name = "Partial Preload Example",
    species = "Mus musculus",
    analyst = "partial@abbvie.com",
    category_selection = "Therapeutic area",
    experiment_type = "in vivo",
    # Note: Missing many fields to demonstrate partial preload handling
    user_confirmation = FALSE
  )
  
  # Initialize with no preload
  CDM <- metaDataServer(
    "metaDataCollector",
    tool = "Artemis",
    preload = FALSE,
    preload_list = list()
  )
  
  # Demo button handlers
  observeEvent(input$demo_basic, {
    current_preload(basic_preload)
    showNotification("Reloading with basic preload configuration...", type = "message")
    
    # Reinitialize the server with basic preload
    CDM <<- metaDataServer(
      "metaDataCollector",
      tool = "Artemis",
      preload = TRUE,
      preload_list = basic_preload
    )
  })
  
  observeEvent(input$demo_comprehensive, {
    current_preload(comprehensive_preload)
    showNotification("Reloading with comprehensive preload configuration...", type = "message")
    
    # Reinitialize the server with comprehensive preload
    CDM <<- metaDataServer(
      "metaDataCollector",
      tool = "Artemis",
      preload = TRUE,
      preload_list = comprehensive_preload
    )
  })
  
  observeEvent(input$demo_partial, {
    current_preload(partial_preload)
    showNotification("Reloading with partial preload configuration...", type = "message")
    
    # Reinitialize the server with partial preload
    CDM <<- metaDataServer(
      "metaDataCollector",
      tool = "Artemis",
      preload = TRUE,
      preload_list = partial_preload
    )
  })
  
  observeEvent(input$reset_demo, {
    current_preload(NULL)
    showNotification("Resetting to no preload...", type = "message")
    
    # Reinitialize the server with no preload
    CDM <<- metaDataServer(
      "metaDataCollector",
      tool = "Artemis",
      preload = FALSE,
      preload_list = list()
    )
  })
  
  # Debug outputs
  output$debug_info <- renderText({
    if (is.null(current_preload())) {
      return("No preload configuration active")
    }
    
    paste(
      "Active Preload Configuration:",
      paste(names(current_preload()), collapse = ", "),
      "\n\nPreload List Length:", length(current_preload()),
      "\n\nSample Fields:",
      paste(utils::capture.output(utils::str(current_preload()[1:min(5, length(current_preload()))])), collapse = "\n")
    )
  })
  
  output$current_state <- renderText({
    if (is.null(CDM)) {
      return("CDM not initialized")
    }
    
    # Safely extract some current state information
    tryCatch({
      paste(
        "Analysis Name:", ifelse(is.null(CDM$analysis$name), "Not set", CDM$analysis$name),
        "\nSpecies:", ifelse(is.null(CDM$samples$species), "Not set", CDM$samples$species),
        "\nTrait:", ifelse(is.null(CDM$CDM_meta$trait), "Not set", CDM$CDM_meta$trait),
        "\nTrait Type:", ifelse(is.null(CDM$CDM_meta$trait_type), "Not set", CDM$CDM_meta$trait_type)
      )
    }, error = function(e) {
      paste("Error accessing CDM state:", e$message)
    })
  })
  
  output$preload_validation <- renderText({
    if (is.null(current_preload())) {
      return("No preload data to validate")
    }
    
    validation <- validate_preload_data(current_preload())
    
    paste(
      "Validation Status:", ifelse(validation$valid, "VALID", "INVALID"),
      "\nPreloaded Fields:", validation$preloaded_count, "of", validation$total_fields,
      "\nErrors:", length(validation$errors),
      "\nWarnings:", length(validation$warnings),
      if (length(validation$errors) > 0) paste("\n\nErrors:\n", paste(validation$errors, collapse = "\n")),
      if (length(validation$warnings) > 0) paste("\n\nWarnings:\n", paste(validation$warnings, collapse = "\n"))
    )
  })
  
  # Monitor CDM changes for debugging
  observe({
    if (!is.null(CDM)) {
      # This observer helps track when CDM values change
      # Useful for debugging preload functionality
    }
  })
}

# Run the application
shinyApp(ui = ui, server = server)

