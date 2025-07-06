# Preload Utility Functions for ARTEMIS Metadata Collection
# This file contains helper functions for managing preload data

library(jsonlite)

# Function to save current metadata state to a preload configuration
save_metadata_state <- function(metadata_state, file_path = NULL) {
  preload_config <- create_comprehensive_preload_list(metadata_state)
  
  if (!is.null(file_path)) {
    # Save to JSON file
    tryCatch({
      write_json(preload_config, file_path, pretty = TRUE, auto_unbox = TRUE)
      return(list(success = TRUE, message = paste("Preload configuration saved to", file_path)))
    }, error = function(e) {
      return(list(success = FALSE, message = paste("Error saving preload configuration:", e$message)))
    })
  }
  
  return(preload_config)
}

# Function to load preload configuration from file
load_preload_config <- function(file_path) {
  tryCatch({
    config <- read_json(file_path, simplifyVector = TRUE)
    validation <- validate_preload_data(config)
    
    return(list(
      success = TRUE,
      config = config,
      validation = validation,
      message = paste("Loaded preload configuration with", validation$preloaded_count, "fields")
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      config = NULL,
      validation = NULL,
      message = paste("Error loading preload configuration:", e$message)
    ))
  })
}

# Enhanced function to create comprehensive preload list
create_comprehensive_preload_list <- function(metadata_state) {
  # Helper function to safely extract reactive values
  safe_extract <- function(reactive_obj, field_name, default = NULL) {
    tryCatch({
      if (is.reactive(reactive_obj)) {
        value <- reactive_obj()
        if (is.list(value) && !is.null(value[[field_name]])) {
          return(value[[field_name]])
        }
        return(value)
      } else if (is.list(reactive_obj) && !is.null(reactive_obj[[field_name]])) {
        return(reactive_obj[[field_name]])
      }
      return(default)
    }, error = function(e) {
      return(default)
    })
  }
  
  # Helper function to extract all reactive values
  extract_reactive_values <- function(reactive_obj) {
    tryCatch({
      if (is.reactivevalues(reactive_obj)) {
        return(reactiveValuesToList(reactive_obj))
      }
      return(reactive_obj)
    }, error = function(e) {
      return(list())
    })
  }
  
  preload_list <- list(
    # Metadata version for compatibility checking
    preload_version = "1.0.0",
    created_timestamp = Sys.time(),
    
    # Basic fields
    study_name = safe_extract(metadata_state$analysis, "name"),
    therapeutic_area = safe_extract(metadata_state$CDM_meta, "therapeutic"),
    species = safe_extract(metadata_state$samples, "species"),
    main_comparison = safe_extract(metadata_state$analysis, "trait"),
    token_ct = safe_extract(metadata_state, "token"),
    analyst = safe_extract(metadata_state$analysis, "analyst_email"),
    number_of_samples = safe_extract(metadata_state$samples, "name"),
    
    # UI state fields (these would need to be captured from the UI state)
    category_selection = NULL, # Would need UI state capture
    main_question = NULL, # Would need UI state capture
    trait_type_selection = safe_extract(metadata_state$CDM_meta, "trait_type"),
    model_type = NULL, # Would need UI state capture
    experiment_type = safe_extract(metadata_state$assays_metadata, "experiment_type"),
    data_generated_at = NULL, # Would need UI state capture
    data_source = safe_extract(metadata_state$assays_metadata, "data_source"),
    effect_type = NULL, # Would need UI state capture
    target_known = NULL, # Would need UI state capture
    effect_known = NULL, # Would need UI state capture
    is_ipsc_derived = NULL, # Would need UI state capture
    
    # Detailed metadata
    trait_details = safe_extract(metadata_state$CDM_meta, "trait_details"),
    strain = safe_extract(metadata_state$CDM_meta, "strain"),
    data_generated_by = safe_extract(metadata_state$assays_metadata, "data_generated_by"),
    data_source_link = safe_extract(metadata_state$assays_metadata, "data_source_link"),
    cell_info_2 = safe_extract(metadata_state$CDM_meta, "protocol"),
    
    # Complete reactive values
    CDM_meta = extract_reactive_values(metadata_state$CDM_meta),
    assays_metadata = extract_reactive_values(metadata_state$assays_metadata),
    samples = extract_reactive_values(metadata_state$samples),
    analysis = extract_reactive_values(metadata_state$analysis),
    features_metadata = extract_reactive_values(metadata_state$features_metadata),
    
    # Multiple selections
    multiple_selections = if (!is.null(metadata_state$multiple_selections)) {
      list(
        multiple_treat = safe_extract(metadata_state$multiple_selections, "multiple_treat"),
        multiple_gene = safe_extract(metadata_state$multiple_selections, "multiple_gene"),
        multiple_cell = safe_extract(metadata_state$multiple_selections, "multiple_cell"),
        multiple_tissue = safe_extract(metadata_state$multiple_selections, "multiple_tissue"),
        multiple_disease = safe_extract(metadata_state$multiple_selections, "multiple_disease"),
        multiple_pheno = safe_extract(metadata_state$multiple_selections, "multiple_pheno"),
        multiple_therapeutic = safe_extract(metadata_state$multiple_selections, "multiple_therapeutic"),
        multiple_line = safe_extract(metadata_state$multiple_selections, "multiple_line")
      )
    } else {
      list()
    },
    
    # Confirmation states
    confirmation_states = if (!is.null(metadata_state$confirmation_states)) {
      list(
        user_confirmation = safe_extract(metadata_state$confirmation_states, "user_confirmation"),
        user_confirmation_2nd_layer = safe_extract(metadata_state$confirmation_states, "user_confirmation_2nd_layer"),
        user_confirmation_3rd_layer = safe_extract(metadata_state$confirmation_states, "user_confirmation_3rd_layer"),
        user_confirmation_4th_layer = safe_extract(metadata_state$confirmation_states, "user_confirmation_4th_layer")
      )
    } else {
      list()
    }
  )
  
  # Remove NULL values to keep the preload list clean
  preload_list <- preload_list[!sapply(preload_list, is.null)]
  
  return(preload_list)
}

# Function to merge preload configurations
merge_preload_configs <- function(base_config, override_config) {
  if (is.null(base_config)) return(override_config)
  if (is.null(override_config)) return(base_config)
  
  merged_config <- base_config
  
  # Recursively merge lists
  merge_recursive <- function(base, override) {
    for (name in names(override)) {
      if (is.list(base[[name]]) && is.list(override[[name]])) {
        base[[name]] <- merge_recursive(base[[name]], override[[name]])
      } else {
        base[[name]] <- override[[name]]
      }
    }
    return(base)
  }
  
  merged_config <- merge_recursive(merged_config, override_config)
  return(merged_config)
}

# Function to create preload template for specific study types
create_preload_template <- function(study_type = "gene_modulation") {
  templates <- list(
    gene_modulation = list(
      category_selection = "Disease indication",
      main_question = "Changes introduced by gene modulation",
      trait_type_selection = "Gene impact",
      target_known = "target known",
      effect_known = "Yes",
      effect_type = "knock out",
      experiment_type = "in vitro",
      data_source = "Internal",
      CDM_meta = list(
        trait_type = "Gene impact"
      ),
      confirmation_states = list(
        user_confirmation = TRUE,
        user_confirmation_2nd_layer = TRUE
      )
    ),
    
    compound_treatment = list(
      category_selection = "Disease indication",
      main_question = "Changes introduced by compound/antibody treatment (does not include treatment to introduce a disease phenotype)",
      trait_type_selection = "Treatment",
      target_known = "target known",
      effect_known = "Yes",
      effect_type = "inhibition",
      experiment_type = "in vitro",
      data_source = "Internal",
      CDM_meta = list(
        trait_type = "Treatment"
      ),
      confirmation_states = list(
        user_confirmation = TRUE,
        user_confirmation_2nd_layer = TRUE
      )
    ),
    
    disease_study = list(
      category_selection = "Disease indication",
      main_question = "Changes introduced by disease status only",
      trait_type_selection = "Disease",
      experiment_type = "in vivo",
      data_source = "Internal",
      CDM_meta = list(
        trait_type = "Disease"
      ),
      confirmation_states = list(
        user_confirmation = TRUE
      )
    ),
    
    model_characterization = list(
      category_selection = "None (e.g. only model test)",
      main_question = "Changes observed for model system characterization",
      trait_type_selection = "model characterization",
      experiment_type = "in vitro",
      data_source = "Internal",
      CDM_meta = list(
        trait_type = "model characterization"
      ),
      confirmation_states = list(
        user_confirmation = TRUE,
        user_confirmation_2nd_layer = TRUE
      )
    )
  )
  
  if (study_type %in% names(templates)) {
    return(templates[[study_type]])
  } else {
    warning(paste("Unknown study type:", study_type, ". Available types:", paste(names(templates), collapse = ", ")))
    return(list())
  }
}

# Function to validate preload compatibility with current app version
validate_preload_compatibility <- function(preload_list, current_version = "1.0.0") {
  if (is.null(preload_list$preload_version)) {
    return(list(
      compatible = TRUE,
      message = "No version information in preload data. Assuming compatibility.",
      warnings = c("Preload data lacks version information")
    ))
  }
  
  preload_version <- preload_list$preload_version
  
  # Simple version comparison (in real implementation, use proper version comparison)
  if (preload_version == current_version) {
    return(list(
      compatible = TRUE,
      message = "Preload data is fully compatible",
      warnings = character(0)
    ))
  } else {
    return(list(
      compatible = TRUE, # For now, assume backward compatibility
      message = paste("Preload data version", preload_version, "may have compatibility issues with current version", current_version),
      warnings = c("Version mismatch detected")
    ))
  }
}

# Function to clean up preload data (remove invalid or outdated fields)
cleanup_preload_data <- function(preload_list) {
  # Define valid field names for current version
  valid_basic_fields <- c(
    "preload_version", "created_timestamp", "study_name", "therapeutic_area", 
    "species", "main_comparison", "token_ct", "analyst", "number_of_samples",
    "category_selection", "main_question", "trait_type_selection", "model_type",
    "experiment_type", "data_generated_at", "data_source", "effect_type",
    "target_known", "effect_known", "is_ipsc_derived", "trait_details",
    "strain", "data_generated_by", "data_source_link", "cell_info_2"
  )
  
  valid_complex_fields <- c("CDM_meta", "assays_metadata", "samples", "analysis", 
                           "features_metadata", "multiple_selections", "confirmation_states")
  
  valid_fields <- c(valid_basic_fields, valid_complex_fields)
  
  # Remove invalid fields
  cleaned_list <- preload_list[names(preload_list) %in% valid_fields]
  
  # Log removed fields
  removed_fields <- setdiff(names(preload_list), names(cleaned_list))
  
  return(list(
    cleaned_data = cleaned_list,
    removed_fields = removed_fields,
    message = if (length(removed_fields) > 0) {
      paste("Removed invalid fields:", paste(removed_fields, collapse = ", "))
    } else {
      "No invalid fields found"
    }
  ))
}

# Function to create a preload summary report
create_preload_report <- function(preload_list) {
  if (is.null(preload_list) || length(preload_list) == 0) {
    return("No preload data available")
  }
  
  validation <- validate_preload_data(preload_list)
  compatibility <- validate_preload_compatibility(preload_list)
  
  report <- list(
    summary = list(
      total_fields = length(preload_list),
      preloaded_fields = validation$preloaded_count,
      coverage_percentage = round((validation$preloaded_fields / validation$total_fields) * 100, 1),
      validation_status = ifelse(validation$valid, "VALID", "INVALID"),
      compatibility_status = ifelse(compatibility$compatible, "COMPATIBLE", "INCOMPATIBLE")
    ),
    
    field_breakdown = list(
      basic_fields = sum(names(preload_list) %in% c("study_name", "species", "analyst", "number_of_samples")),
      ui_state_fields = sum(names(preload_list) %in% c("category_selection", "main_question", "experiment_type")),
      metadata_fields = sum(names(preload_list) %in% c("CDM_meta", "assays_metadata", "samples", "analysis")),
      multiple_selections = ifelse("multiple_selections" %in% names(preload_list), 
                                  length(preload_list$multiple_selections), 0),
      confirmation_states = ifelse("confirmation_states" %in% names(preload_list), 
                                  length(preload_list$confirmation_states), 0)
    ),
    
    issues = list(
      errors = validation$errors,
      warnings = c(validation$warnings, compatibility$warnings),
      recommendations = character(0)
    )
  )
  
  # Add recommendations based on analysis
  if (report$summary$coverage_percentage < 50) {
    report$issues$recommendations <- c(report$issues$recommendations, 
                                     "Consider adding more fields to improve preload coverage")
  }
  
  if (length(report$issues$errors) > 0) {
    report$issues$recommendations <- c(report$issues$recommendations, 
                                     "Fix validation errors before using preload data")
  }
  
  return(report)
}

