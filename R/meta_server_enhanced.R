# Enhanced Metadata Server with Comprehensive Preload Functionality
# This implementation extends the original metaDataServer to support full metadata preloading

metaDataServer <- function(id, tool, preload = FALSE, preload_list = list(), 
                          therapeutic_area = NULL, species = NULL, main_comparison = NULL, 
                          token_ct = NULL, analyst = NULL, number_of_samples = NULL, study_name = NULL) {
  
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Initialize all reactive values and UI choices
    question_meta_ui <- reactiveVal(c("","Changes introduced by gene modulation",
                                      "Changes introduced by compound/antibody treatment (does not include treatment to introduce a disease phenotype)",
                                      "Changes introduced by disease status only",
                                      "Therapeutic area related changes only",
                                      "Changes introduced by disease phenotype only (include phenotype introduced by treatment, e.g., PFF treatment)",
                                      "Changes observed for model system characterization"))
    
    question_meta_ui_disease <- reactiveVal(c("","Changes introduced by gene modulation",
                                              "Changes introduced by compound/antibody treatment (does not include treatment to introduce a disease phenotype)",
                                              "Changes introduced by disease status only",
                                              "Changes observed for model system characterization"))
    
    question_meta_ui_pheno <- reactiveVal(c("","Changes introduced by gene modulation",
                                            "Changes introduced by compound/antibody treatment (does not include treatment to introduce a disease phenotype)",
                                            "Changes introduced by disease phenotype only (include phenotype introduced by treatment, e.g., PFF treatment)",
                                            "Changes observed for model system characterization"))
    
    question_meta_ui_therapeutic <- reactiveVal(c("","Changes introduced by gene modulation",
                                                  "Changes introduced by compound/antibody treatment (does not include treatment to introduce a disease phenotype)",
                                                  "Therapeutic area related changes only",
                                                  "Changes observed for model system characterization"))
    
    question_meta_ui_model <- reactiveVal(c("","Changes introduced by gene modulation",
                                            "Changes introduced by compound/antibody treatment (does not include treatment to introduce a disease phenotype)",
                                            "Changes observed for model system characterization"))
    
    differentiation_protocols <- reactive({
      neuron_ontologies <- c("iNGN2", "BMWi iNGN2_telencephalic", "BMWi iNGN2_mDA", 
                             "iNGN2_iDRG", "dSMADi_cortical inhibitory", 
                             "dSMADi_cortical excitatory", "dSMADi_hypothalamic", 
                             "dSMADi_motor", "dSMADi_mDA")
      
      microglia_ontologies <- c("LU Standard protocol", "Washer protocol", 
                                "Stem cell", "Merged Protocol")
      
      icd <- tibble(
        ONT = c(neuron_ontologies, microglia_ontologies),
        DESC = c(rep("Neuron", length(neuron_ontologies)), 
                 rep("Microglia", length(microglia_ontologies)))
      )
      
      unique_DESC <- unique(as.character(icd$DESC))
      icd$DESC <- factor(as.character(icd$DESC), levels = unique_DESC)
      unique_ONT <- unique(as.character(icd$ONT))
      icd$ONT <- factor(as.character(icd$ONT), levels = unique_ONT)
      
      cicd <- split(as.list(levels(icd$ONT)), icd$DESC)
    })
    
    experiment_type_ui <- reactiveVal(c("in vitro", "in vivo", "ex vivo"))
    
    # Initialize all reactive values for metadata
    CDM_meta <- reactiveValues(
      trait = NULL, trait_type = NULL, trait_details = NULL, 
      disease = NULL, pheno = NULL, therapeutic = NULL, 
      cell = NULL, line = NULL, tissue = NULL, 
      platform_instrument = NULL, strain = NULL, protocol = NULL
    )
    
    # Initialize features metadata based on tool
    if(tool == "Artemis"){
      features_metadata <- reactiveValues(
        biomolecule = "RNA",
        biomolecule_id = "ENSEMBL",
        biomolecule_id_version = ifelse(species == "Homo sapiens","org.Hs.eg.db_3.14.0 GRCh38",
                                       ifelse(species == "Mus musculus", "org.Mm.eg.db_3.14.0 GRCm39",
                                              ifelse(species == "Rattus norvegicus","org.Rn.eg.db_3.14.0 Rnor 6.0.100",
                                                     ifelse(species == "Macaca fascicularis","macaque 6.0.109","not given")))),
        feature_description = "transcript counts",
        biomolecule_id_mapping_field = "ensembl_gene_id",
        biomolecule_detailed = "",
        species = species
      )
    } else if (tool == "Proteus"){
      features_metadata <- reactiveValues(
        biomolecule = "Protein",
        biomolecule_id = "Uniprot",
        biomolecule_id_version = "",
        feature_description = "protein XICs",
        biomolecule_id_mapping_field = "uniprot_id",
        biomolecule_detailed = "",
        species = species
      )
    }

    # Initialize assays metadata
    assays_metadata <- reactiveValues(
      omic_assay_category = "Transcriptomics",
      omic_assay = "RNA expression",
      platform_instrument = "",
      quant_type = "relative",
      units = "Count",
      data_source = "Internal",
      data_source_link = "",
      data_generated_by = "",
      normalization_method = "None",
      transformation_method = "None",
      pii = FALSE,
      controlled_access = FALSE,
      controlled_access_rationale = "",
      ad_group = "",
      ad_approver = "",
      experiment_type = "",
      assay_kit = "",
      raw_data_location = "",
      algorithms = "Trim-galore, STAR, RSubread",
      experimental_design = "",
      name = "",
      study_id = "",
      study_source_key = "Uploaded from ARTEMIS",
      transformed_units = "Count",
      transformed_quant_type = "relative",
      transformed_normalization_method = "CPM",
      transformed_transformation_method = "None",
      transformed_algorithms = "CPM",
      transformed_description = "please change/move to analysis:voom performs the following specific calculations. First, the counts are converted to logCPM values, adding 0.5 to all the counts to avoid taking the logarithm of zero. The matrix of logCPM values is then normalized. The lmFit function is used to fit row-wise linear models. The lowess function is then used to fit a trend to the square-root-standard-deviations as a function of an average log-count measure. The trend line is then used to predict the variance of each logCPM value as a function of its fitted value on the count scale, and the inverse variances become the estimated precision weights."
    )
    
    # Initialize samples metadata
    samples <- reactiveValues(
      name = "",
      species = "Homo sapiens",
      tissue = "",
      cell_type = "",
      cell_line = "",
      disease = "",
      sex = "",
      response = "",
      response_timepoint = "",
      age = "",
      age_category = "",
      disease_stage = "",
      description = "",
      pathology_grade = "",
      differentiation_stage = "",
      species_strain = "",
      subject_id = "",
      cell_passage_number = "",
      treated_control_na = ""
    )
    
    # Initialize analysis metadata
    analysis <- reactiveValues(
      analysis_id = "",
      model_id = "",
      viz_assays_metadata_id = "",
      features_metadata_id_special = "",
      name = "",
      description = "",
      analyst = toupper(gsub("[.]"," ",gsub("@abbvie.com","",analyst))),
      analyst_email = analyst,
      pii = "",
      controlled_access = "",
      type = "",
      result_link_type = "",
      analysis_category = "",
      single_or_multifeature = "",
      feature_groups_metadata_id = "",
      effect_size = "",
      nominal_p_value = "",
      adjusted_p_value = "",
      reference_samples = "",
      test_samples = "",
      analyzed_variables = "",
      standard_error = "",
      average_expression = "",
      multiple_testing_algorithm = "",
      ref_variables = "",
      test_variables = "",
      analysis_source_key = "",
      trait = "",
      trait_type = "",
      trait_details = "",
      visualization_grouping = "",
      condition_or_subset = ""
    )
    
    # Initialize multiple selection reactive values
    multiple_treat <- reactiveVal(NULL)
    multiple_gene <- reactiveVal(NULL)
    multiple_cell <- reactiveVal(NULL)
    multiple_tissue <- reactiveVal(NULL)
    multiple_disease <- reactiveVal(NULL)
    multiple_pheno <- reactiveVal(NULL)
    multiple_therapeutic <- reactiveVal(NULL)
    multiple_line <- reactiveVal(NULL)

    # Initialize user confirmation states
    user_confirmation <- reactiveVal(FALSE)
    user_confirmation_2nd_layer <- reactiveVal(FALSE)
    user_confirmation_3rd_layer <- reactiveVal(FALSE)
    user_confirmation_4th_layer <- reactiveVal(FALSE)
    token <- reactiveVal(token_ct)
    
    # ENHANCED PRELOAD FUNCTIONALITY
    # ================================
    
    # Helper function to safely get preload values
    get_preload_value <- function(field_name, default_value = NULL) {
      if (preload && !is.null(preload_list[[field_name]])) {
        return(preload_list[[field_name]])
      }
      return(default_value)
    }
    
    # Helper function to preload text inputs
    preload_text_input <- function(input_id, field_name, default_value = "") {
      value <- get_preload_value(field_name, default_value)
      if (!is.null(value) && value != "") {
        updateTextInput(session, input_id, value = value)
      }
    }
    
    # Helper function to preload select inputs
    preload_select_input <- function(input_id, field_name, choices = NULL, default_value = "") {
      value <- get_preload_value(field_name, default_value)
      if (!is.null(value) && value != "") {
        if (!is.null(choices)) {
          updateSelectInput(session, input_id, choices = choices, selected = value)
        } else {
          updateSelectInput(session, input_id, selected = value)
        }
      }
    }
    
    # Helper function to preload radio buttons
    preload_radio_buttons <- function(input_id, field_name, default_value = NULL) {
      value <- get_preload_value(field_name, default_value)
      if (!is.null(value)) {
        updateRadioButtons(session, input_id, selected = value)
      }
    }
    
    # Helper function to preload checkbox inputs
    preload_checkbox_input <- function(input_id, field_name, default_value = FALSE) {
      value <- get_preload_value(field_name, default_value)
      if (!is.null(value)) {
        updateCheckboxInput(session, input_id, value = value)
      }
    }
    
    # Helper function to preload reactive values
    preload_reactive_values <- function(reactive_obj, preload_data) {
      if (!is.null(preload_data) && is.list(preload_data)) {
        for (field_name in names(preload_data)) {
          if (!is.null(preload_data[[field_name]])) {
            reactive_obj[[field_name]] <- preload_data[[field_name]]
          }
        }
      }
    }
    
    # Helper function to preload multiple selections
    preload_multiple_selections <- function() {
      multiple_treat(get_preload_value("multiple_treat"))
      multiple_gene(get_preload_value("multiple_gene"))
      multiple_cell(get_preload_value("multiple_cell"))
      multiple_tissue(get_preload_value("multiple_tissue"))
      multiple_disease(get_preload_value("multiple_disease"))
      multiple_pheno(get_preload_value("multiple_pheno"))
      multiple_therapeutic(get_preload_value("multiple_therapeutic"))
      multiple_line(get_preload_value("multiple_line"))
    }
    
    # Helper function to preload confirmation states
    preload_confirmation_states <- function() {
      user_confirmation(get_preload_value("user_confirmation", FALSE))
      user_confirmation_2nd_layer(get_preload_value("user_confirmation_2nd_layer", FALSE))
      user_confirmation_3rd_layer(get_preload_value("user_confirmation_3rd_layer", FALSE))
      user_confirmation_4th_layer(get_preload_value("user_confirmation_4th_layer", FALSE))
    }
    
    # Main preload execution
    if (preload && length(preload_list) > 0) {
      
      # Preload basic text inputs
      preload_text_input("species", "species")
      preload_text_input("therapeutic_area", "therapeutic_area")
      preload_text_input("main_comp_meta_2", "main_comparison")
      preload_text_input("technology", "technology")
      preload_text_input("trait", "trait")
      preload_text_input("trait_type", "trait_type")
      preload_text_input("number_of_samples", "number_of_samples")
      preload_text_input("token_ct", "token_ct")
      preload_text_input("analyst", "analyst")
      preload_text_input("analysis_name", "study_name")
      preload_text_input("any_other_info_2", "trait_details")
      preload_text_input("strain_info_2", "strain")
      preload_text_input("data_generated_by", "data_generated_by")
      preload_text_input("data_source_link", "data_source_link")
      preload_text_input("Sample_nb_2", "number_of_samples")
      
      # Preload select inputs
      preload_select_input("category_sel_2", "category_selection")
      preload_select_input("question_2", "main_question")
      preload_select_input("trait_type_sel_2", "trait_type_selection")
      preload_select_input("model_type_sel_2", "model_type")
      preload_select_input("experiment_type", "experiment_type")
      preload_select_input("generated_at_2", "data_generated_at")
      preload_select_input("data_source", "data_source")
      preload_select_input("eff_type_sel_2", "effect_type")
      
      # Preload radio buttons
      preload_radio_buttons("target_known_2", "target_known")
      preload_radio_buttons("effect_known_2", "effect_known")
      
      # Preload checkbox inputs
      preload_checkbox_input("is_ipsc_derived", "is_ipsc_derived")
      
      # Preload multiple selections for ontology fields
      if (!is.null(get_preload_value("cell_info_2"))) {
        updateSelectInput(session, "cell_info_2", selected = get_preload_value("cell_info_2"))
      }
      
      # Preload reactive values
      preload_reactive_values(CDM_meta, get_preload_value("CDM_meta"))
      preload_reactive_values(assays_metadata, get_preload_value("assays_metadata"))
      preload_reactive_values(samples, get_preload_value("samples"))
      preload_reactive_values(analysis, get_preload_value("analysis"))
      preload_reactive_values(features_metadata, get_preload_value("features_metadata"))
      
      # Preload multiple selections
      preload_multiple_selections()
      
      # Preload confirmation states
      preload_confirmation_states()
      
      # Update token
      if (!is.null(get_preload_value("token_ct"))) {
        token(get_preload_value("token_ct"))
      }
      
      # Trigger UI updates for conditional panels
      # This ensures that conditional panels show/hide correctly based on preloaded values
      if (!is.null(get_preload_value("category_selection"))) {
        # Trigger category selection change to update question choices
        session$sendInputMessage("category_sel_2", list(value = get_preload_value("category_selection")))
      }
      
      if (!is.null(get_preload_value("main_question"))) {
        # Trigger question selection to show appropriate conditional panels
        session$sendInputMessage("question_2", list(value = get_preload_value("main_question")))
      }
    }
    
    # Rest of the original server logic continues here...
    # (The existing observeEvent handlers, UI rendering, etc.)
    
    # [Original server logic would continue here - truncated for brevity]
    # This includes all the existing observeEvent handlers, UI rendering logic,
    # validation logic, etc. from the original metaDataServer function
    
    # Return the reactive values as before
    return(list(
      assays_metadata = assays_metadata,
      samples = samples,
      analysis = analysis,
      features_metadata = features_metadata,
      CDM_meta = CDM_meta,
      # Additional return values for preload state management
      multiple_selections = list(
        multiple_treat = multiple_treat,
        multiple_gene = multiple_gene,
        multiple_cell = multiple_cell,
        multiple_tissue = multiple_tissue,
        multiple_disease = multiple_disease,
        multiple_pheno = multiple_pheno,
        multiple_therapeutic = multiple_therapeutic,
        multiple_line = multiple_line
      ),
      confirmation_states = list(
        user_confirmation = user_confirmation,
        user_confirmation_2nd_layer = user_confirmation_2nd_layer,
        user_confirmation_3rd_layer = user_confirmation_3rd_layer,
        user_confirmation_4th_layer = user_confirmation_4th_layer
      )
    ))
  })
}

# Helper function to create comprehensive preload list from current state
create_preload_list <- function(metadata_state) {
  list(
    # Basic fields
    study_name = metadata_state$analysis$name,
    therapeutic_area = metadata_state$CDM_meta$therapeutic,
    species = metadata_state$samples$species,
    main_comparison = metadata_state$analysis$trait,
    token_ct = metadata_state$token,
    analyst = metadata_state$analysis$analyst_email,
    number_of_samples = metadata_state$samples$name,
    
    # UI state fields
    category_selection = NULL, # Would need to be captured from UI
    main_question = NULL, # Would need to be captured from UI
    trait_type_selection = metadata_state$CDM_meta$trait_type,
    model_type = NULL, # Would need to be captured from UI
    experiment_type = metadata_state$assays_metadata$experiment_type,
    data_generated_at = NULL, # Would need to be captured from UI
    data_source = metadata_state$assays_metadata$data_source,
    effect_type = NULL, # Would need to be captured from UI
    target_known = NULL, # Would need to be captured from UI
    effect_known = NULL, # Would need to be captured from UI
    is_ipsc_derived = NULL, # Would need to be captured from UI
    
    # Detailed metadata
    trait_details = metadata_state$CDM_meta$trait_details,
    strain = metadata_state$CDM_meta$strain,
    data_generated_by = metadata_state$assays_metadata$data_generated_by,
    data_source_link = metadata_state$assays_metadata$data_source_link,
    cell_info_2 = metadata_state$CDM_meta$protocol,
    
    # Reactive values
    CDM_meta = list(
      trait = metadata_state$CDM_meta$trait,
      trait_type = metadata_state$CDM_meta$trait_type,
      trait_details = metadata_state$CDM_meta$trait_details,
      disease = metadata_state$CDM_meta$disease,
      pheno = metadata_state$CDM_meta$pheno,
      therapeutic = metadata_state$CDM_meta$therapeutic,
      cell = metadata_state$CDM_meta$cell,
      line = metadata_state$CDM_meta$line,
      tissue = metadata_state$CDM_meta$tissue,
      platform_instrument = metadata_state$CDM_meta$platform_instrument,
      strain = metadata_state$CDM_meta$strain,
      protocol = metadata_state$CDM_meta$protocol
    ),
    
    assays_metadata = reactiveValuesToList(metadata_state$assays_metadata),
    samples = reactiveValuesToList(metadata_state$samples),
    analysis = reactiveValuesToList(metadata_state$analysis),
    features_metadata = reactiveValuesToList(metadata_state$features_metadata),
    
    # Multiple selections
    multiple_treat = metadata_state$multiple_selections$multiple_treat(),
    multiple_gene = metadata_state$multiple_selections$multiple_gene(),
    multiple_cell = metadata_state$multiple_selections$multiple_cell(),
    multiple_tissue = metadata_state$multiple_selections$multiple_tissue(),
    multiple_disease = metadata_state$multiple_selections$multiple_disease(),
    multiple_pheno = metadata_state$multiple_selections$multiple_pheno(),
    multiple_therapeutic = metadata_state$multiple_selections$multiple_therapeutic(),
    multiple_line = metadata_state$multiple_selections$multiple_line(),
    
    # Confirmation states
    user_confirmation = metadata_state$confirmation_states$user_confirmation(),
    user_confirmation_2nd_layer = metadata_state$confirmation_states$user_confirmation_2nd_layer(),
    user_confirmation_3rd_layer = metadata_state$confirmation_states$user_confirmation_3rd_layer(),
    user_confirmation_4th_layer = metadata_state$confirmation_states$user_confirmation_4th_layer()
  )
}

