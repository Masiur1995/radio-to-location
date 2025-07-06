# Enhanced Metadata UI with Preload Support
# This implementation provides the UI components for the enhanced metadata collection

library(shiny)
library(shinyjs)

metaDataUI <- function(id, tool, runsStandlone = TRUE) {
  ns <- NS(id)
  ns_study_meta <- ns("analysis_name")
  ns_main_comp_meta <- ns("main_comp_meta_2")
  ns_category_sel <- ns("category_sel_2")
  ns_disease_type_sel <- ns("disease_type_sel_2")
  ns_cell_type_sel <- ns("cell_type_sel_2")
  ns_meta_modal <- ns("Meta_Odin_2")
  
  if(!runsStandlone){
    addResourcePath("MetaTool","MetaTool/www")
  }
  
  fluidPage(
    br(),
    useShinyjs(),
    
    # Enhanced CSS for preload indicators
    tags$head(
      tags$style(HTML("
        .overlay-image {
          position: absolute;
          z-index: 1051;
          display: none;
        }
        
        /* Preload indicator styles */
        .preloaded-field {
          background-color: #e8f5e8 !important;
          border-left: 4px solid #28a745 !important;
        }
        
        .preloaded-field .form-control {
          background-color: #e8f5e8 !important;
        }
        
        .preload-indicator {
          color: #28a745;
          font-size: 12px;
          font-style: italic;
          margin-top: 2px;
        }
        
        .preload-status {
          background-color: #d4edda;
          border: 1px solid #c3e6cb;
          border-radius: 4px;
          padding: 8px 12px;
          margin-bottom: 15px;
          color: #155724;
        }
        
        .preload-status .preload-count {
          font-weight: bold;
        }
        
        /* Enhanced confirmation styles */
        .confirmed-parent { 
          background-color: #e6ffe6; 
        }
        
        .confirmed-field {
          background-color: #d4edda !important;
          border-color: #c3e6cb !important;
        }
      ")),
      
      # Enhanced JavaScript for positioning and preload handling
      tags$script(HTML(sprintf("
        function positionImage(inputId, imageClass, switchCord) {
          var input = document.getElementById(inputId);
          var img = document.querySelector(imageClass);
          if (input && img) {
            var rect = input.getBoundingClientRect();
            img.style.top = (rect.top + window.scrollY - 20) + 'px';
            if (switchCord) {
              img.style.right = (rect.left + window.scrollX - img.width - 140) + 'px';
            } else {
              img.style.left = (rect.left + window.scrollX - img.width - 25) + 'px';
            }
            img.style.display = 'block';
          }
        }

        function repositionImages() {
          positionImage('%s', '.image-for-textinput', false);
          positionImage('%s', '.image-for-selectinput', true);
          positionImage('%s', '.image-for-radioinput', false);
          positionImage('%s', '.image-for-dropdowninput', true);
          positionImage('%s', '.image-for-selectinput2', true);
        }
        
        // Enhanced preload handling
        function markPreloadedFields() {
          // Mark fields that were preloaded
          $('.preloaded-field').each(function() {
            var fieldId = $(this).attr('id');
            if (fieldId) {
              var field = $('#' + fieldId);
              if (field.length > 0 && field.val() !== '') {
                field.addClass('preloaded-field');
                // Add preload indicator
                if (!field.siblings('.preload-indicator').length) {
                  field.after('<div class=\"preload-indicator\">✓ Preloaded</div>');
                }
              }
            }
          });
        }
        
        // Function to show preload status
        function showPreloadStatus(preloadedCount, totalFields) {
          var statusHtml = '<div class=\"preload-status\">' +
            '<strong>Preload Status:</strong> ' +
            '<span class=\"preload-count\">' + preloadedCount + '</span> of ' +
            '<span class=\"preload-count\">' + totalFields + '</span> fields restored from previous session' +
            '</div>';
          $('#preload-status-container').html(statusHtml);
        }

        $(document).on('shown.bs.modal', '#%s', function() {
          setTimeout(function() {
            repositionImages();
            markPreloadedFields();
          }, 100);
          
          $('#%s').on('scroll', function() {
            repositionImages();
          });
        });

        $(window).on('resize', function() {
          repositionImages();
        });
        
        // Initialize preload indicators on document ready
        $(document).ready(function() {
          setTimeout(markPreloadedFields, 500);
        });
      ", ns_study_meta, ns_main_comp_meta, ns_category_sel, ns_disease_type_sel, 
         ns_cell_type_sel, ns_meta_modal, ns_meta_modal)))
    ),
    
    # Preload status indicator
    div(id = "preload-status-container"),
    
    # Enhanced action button with preload indicator
    div(
      style = "margin-bottom: 20px;",
      actionButton(
        ns("ODIN_2"), 
        "Add obligatory Meta-data (analysis level)", 
        icon("list-alt"), 
        style = "color: #fff; background-color: #CCCCFF; border-color: #CCCCFF; border-radius: 10px; border-width: 2px; padding: 4px; font-size: 100%;"
      ),
      # Preload info button
      actionButton(
        ns("preload_info"),
        "",
        icon = icon("info-circle"),
        style = "margin-left: 10px; background-color: transparent; border: none; color: #007bff;",
        title = "Click to see preload information"
      )
    ),
    
    # Main UI output
    uiOutput(ns("meta_ui_2")),
    
    # Help images (conditional based on standalone mode)
    if(runsStandlone){
      tagList(
        img(src = "help_studyname.PNG", class = "overlay-image image-for-textinput", height = "10%", width = "20%"),
        img(src = "help_comp.PNG", class = "overlay-image image-for-selectinput", height = "10%", width = "20%"),
        img(src = "help_category.PNG", class = "overlay-image image-for-radioinput", height = "15%", width = "20%"),
        img(src = "help_trait.PNG", class = "overlay-image image-for-dropdowninput", height = "10%", width = "20%")
      )
    } else {
      tagList(
        img(src = "MetaTool/help_studyname.PNG", class = "overlay-image image-for-textinput", height = "10%", width = "20%"),
        img(src = "MetaTool/help_comp.PNG", class = "overlay-image image-for-selectinput", height = "10%", width = "20%"),
        img(src = "MetaTool/help_category.PNG", class = "overlay-image image-for-radioinput", height = "15%", width = "20%"),
        img(src = "MetaTool/help_trait.PNG", class = "overlay-image image-for-dropdowninput", height = "10%", width = "20%")
      )
    },
    
    # Enhanced modal styles
    tags$style(HTML(sprintf("
      #%s .modal-footer .btn-default { 
        display: none; 
      }
      #%s .modal-content { 
        width: 120%% !important; 
        max-width: 120%% !important; 
      }
      .col-sm-3 { 
        width: 40%%; 
      } 
      .col-sm-9 { 
        width: 60%%; 
      }
    ", ns_meta_modal, ns_meta_modal))),
    
    # Enhanced modal behavior
    tags$script(HTML(sprintf("
      $(document).on('show.bs.modal', '#%s', function () {
        $(this).data('bs.modal').options.backdrop = 'static';
        $(this).find('.modal-header .close').hide();
      });
    ", ns_meta_modal)))
  )
}

# Helper function to create ontology input UI with preload support
onto_ui_input <- function(ns, type, quest = NULL, label_id = "Field") {
  input_id <- paste0(type, "_type_sel_2")
  sugg_id <- paste0(type, "_type_sel_sugg_2")
  div_id <- paste0(type, "_type_sel_sugg_2_div")
  
  tagList(
    # Text input for search
    textInput(
      ns(input_id), 
      label = paste("Enter", label_id), 
      value = "",
      placeholder = paste("Type to search for", tolower(label_id))
    ),
    
    # Suggestion dropdown (initially hidden)
    div(
      id = ns(div_id),
      style = "display: none;",
      selectInput(
        ns(sugg_id),
        label = paste("Suggested", label_id),
        choices = c("Loading..." = "loading"),
        selected = NULL
      )
    ),
    
    # Action buttons for confirmation
    div(
      style = "margin: 10px 0;",
      actionButton(
        ns(paste0("conf_sel_", type)),
        "✓ Confirm Selection",
        class = "btn btn-success btn-sm",
        style = "margin-right: 5px;"
      ),
      actionButton(
        ns(paste0("not_conf_sel_", type)),
        "✗ Use Original",
        class = "btn btn-warning btn-sm",
        style = "margin-right: 5px;"
      ),
      actionButton(
        ns(paste0("add_element_", type)),
        "+ Add Another",
        class = "btn btn-info btn-sm",
        style = "margin-right: 5px;"
      ),
      actionButton(
        ns(paste0("remove_element_", type)),
        "- Remove Last",
        class = "btn btn-secondary btn-sm",
        style = "display: none;"
      )
    ),
    
    # Multiple selections display
    div(
      id = ns(paste0("multiple_", type, "_container")),
      style = "margin-top: 10px;",
      textOutput(ns(paste0("multiple_", type)))
    ),
    
    # Confirmation buttons for multiple selections
    div(
      id = ns(paste0("multiple_conf_", type)),
      style = "display: none; margin-top: 10px;",
      actionButton(
        ns(paste0("conf_sel_mul_", type)),
        "✓ Confirm All Selections",
        class = "btn btn-success btn-sm"
      )
    )
  )
}

# Enhanced preload validation function
validate_preload_data <- function(preload_list, required_fields = NULL) {
  validation_results <- list(
    valid = TRUE,
    errors = character(0),
    warnings = character(0),
    preloaded_count = 0,
    total_fields = 0
  )
  
  if (is.null(preload_list) || length(preload_list) == 0) {
    validation_results$warnings <- c(validation_results$warnings, "No preload data provided")
    return(validation_results)
  }
  
  # Count total fields that could be preloaded
  expected_fields <- c(
    "study_name", "therapeutic_area", "species", "main_comparison",
    "token_ct", "analyst", "number_of_samples", "category_selection",
    "main_question", "trait_type_selection", "experiment_type",
    "data_source", "trait_details", "strain", "data_generated_by"
  )
  
  validation_results$total_fields <- length(expected_fields)
  
  # Count successfully preloaded fields
  for (field in expected_fields) {
    if (!is.null(preload_list[[field]]) && preload_list[[field]] != "") {
      validation_results$preloaded_count <- validation_results$preloaded_count + 1
    }
  }
  
  # Check for required fields if specified
  if (!is.null(required_fields)) {
    for (field in required_fields) {
      if (is.null(preload_list[[field]]) || preload_list[[field]] == "") {
        validation_results$errors <- c(
          validation_results$errors,
          paste("Required field missing:", field)
        )
        validation_results$valid <- FALSE
      }
    }
  }
  
  # Check for data type consistency
  numeric_fields <- c("number_of_samples")
  for (field in numeric_fields) {
    if (!is.null(preload_list[[field]]) && !is.numeric(preload_list[[field]]) && 
        !is.na(as.numeric(preload_list[[field]]))) {
      validation_results$warnings <- c(
        validation_results$warnings,
        paste("Field", field, "should be numeric")
      )
    }
  }
  
  # Check for logical fields
  logical_fields <- c("is_ipsc_derived", "user_confirmation", "user_confirmation_2nd_layer")
  for (field in logical_fields) {
    if (!is.null(preload_list[[field]]) && !is.logical(preload_list[[field]])) {
      validation_results$warnings <- c(
        validation_results$warnings,
        paste("Field", field, "should be logical (TRUE/FALSE)")
      )
    }
  }
  
  return(validation_results)
}

# Function to create preload summary for display
create_preload_summary <- function(preload_list) {
  if (is.null(preload_list) || length(preload_list) == 0) {
    return("No preload data available")
  }
  
  validation <- validate_preload_data(preload_list)
  
  summary_text <- paste0(
    "Preload Summary:\n",
    "- Fields restored: ", validation$preloaded_count, " of ", validation$total_fields, "\n"
  )
  
  if (length(validation$errors) > 0) {
    summary_text <- paste0(summary_text, "- Errors: ", length(validation$errors), "\n")
  }
  
  if (length(validation$warnings) > 0) {
    summary_text <- paste0(summary_text, "- Warnings: ", length(validation$warnings), "\n")
  }
  
  return(summary_text)
}

