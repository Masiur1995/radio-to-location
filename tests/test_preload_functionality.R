# Test Suite for Enhanced Preload Functionality
# This file contains tests to validate the preload implementation

library(testthat)
library(jsonlite)

# Source the enhanced components
source("../R/preload_utils.R")
source("../R/meta_ui_enhanced.R")

# Test Data
test_basic_preload <- list(
  study_name = "Test Study",
  species = "Homo sapiens",
  analyst = "test@company.com",
  number_of_samples = 10
)

test_comprehensive_preload <- list(
  study_name = "Comprehensive Test",
  species = "Homo sapiens",
  analyst = "test@company.com",
  number_of_samples = 24,
  category_selection = "Disease indication",
  main_question = "Changes introduced by gene modulation",
  experiment_type = "in vitro",
  CDM_meta = list(
    trait = "Test Gene",
    trait_type = "Gene impact",
    disease = "Test Disease"
  ),
  multiple_selections = list(
    multiple_gene = c("GENE1", "GENE2")
  ),
  confirmation_states = list(
    user_confirmation = TRUE
  )
)

test_invalid_preload <- list(
  study_name = 123,  # Should be string
  number_of_samples = "not_a_number",  # Should be numeric
  invalid_field = "should_not_exist"
)

# Test Suite
test_that("Basic preload validation works", {
  validation <- validate_preload_data(test_basic_preload)
  
  expect_true(validation$valid)
  expect_equal(length(validation$errors), 0)
  expect_gt(validation$preloaded_count, 0)
  expect_gt(validation$total_fields, 0)
})

test_that("Comprehensive preload validation works", {
  validation <- validate_preload_data(test_comprehensive_preload)
  
  expect_true(validation$valid)
  expect_equal(length(validation$errors), 0)
  expect_gt(validation$preloaded_count, 4)  # Should have multiple fields
})

test_that("Invalid preload data is caught", {
  validation <- validate_preload_data(test_invalid_preload)
  
  expect_gt(length(validation$warnings), 0)  # Should have warnings about type mismatches
})

test_that("Empty preload data is handled gracefully", {
  validation <- validate_preload_data(list())
  
  expect_true(validation$valid)  # Empty should be valid
  expect_equal(validation$preloaded_count, 0)
  expect_gt(length(validation$warnings), 0)  # Should warn about no data
})

test_that("NULL preload data is handled gracefully", {
  validation <- validate_preload_data(NULL)
  
  expect_true(validation$valid)
  expect_equal(validation$preloaded_count, 0)
})

test_that("Preload templates are created correctly", {
  gene_template <- create_preload_template("gene_modulation")
  
  expect_true(is.list(gene_template))
  expect_true("category_selection" %in% names(gene_template))
  expect_true("main_question" %in% names(gene_template))
  expect_equal(gene_template$main_question, "Changes introduced by gene modulation")
})

test_that("Unknown template type returns empty list with warning", {
  expect_warning(unknown_template <- create_preload_template("unknown_type"))
  expect_equal(length(unknown_template), 0)
})

test_that("Preload config merging works correctly", {
  base_config <- list(
    analyst = "base@company.com",
    species = "Homo sapiens"
  )
  
  override_config <- list(
    analyst = "override@company.com",
    study_name = "Override Study"
  )
  
  merged <- merge_preload_configs(base_config, override_config)
  
  expect_equal(merged$analyst, "override@company.com")  # Should be overridden
  expect_equal(merged$species, "Homo sapiens")  # Should be preserved
  expect_equal(merged$study_name, "Override Study")  # Should be added
})

test_that("Preload config merging handles NULL inputs", {
  base_config <- list(field1 = "value1")
  
  merged_null_override <- merge_preload_configs(base_config, NULL)
  expect_equal(merged_null_override, base_config)
  
  merged_null_base <- merge_preload_configs(NULL, base_config)
  expect_equal(merged_null_base, base_config)
})

test_that("Preload compatibility validation works", {
  preload_with_version <- list(
    preload_version = "1.0.0",
    study_name = "Test"
  )
  
  compatibility <- validate_preload_compatibility(preload_with_version, "1.0.0")
  expect_true(compatibility$compatible)
  expect_equal(length(compatibility$warnings), 0)
})

test_that("Preload compatibility handles missing version", {
  preload_no_version <- list(study_name = "Test")
  
  compatibility <- validate_preload_compatibility(preload_no_version)
  expect_true(compatibility$compatible)
  expect_gt(length(compatibility$warnings), 0)  # Should warn about missing version
})

test_that("Preload data cleanup removes invalid fields", {
  dirty_preload <- list(
    study_name = "Valid Study",
    invalid_field_1 = "Should be removed",
    species = "Homo sapiens",
    another_invalid_field = "Also should be removed",
    CDM_meta = list(trait = "Valid trait")
  )
  
  cleaned <- cleanup_preload_data(dirty_preload)
  
  expect_true("study_name" %in% names(cleaned$cleaned_data))
  expect_true("species" %in% names(cleaned$cleaned_data))
  expect_true("CDM_meta" %in% names(cleaned$cleaned_data))
  expect_false("invalid_field_1" %in% names(cleaned$cleaned_data))
  expect_false("another_invalid_field" %in% names(cleaned$cleaned_data))
  expect_gt(length(cleaned$removed_fields), 0)
})

test_that("Preload report generation works", {
  report <- create_preload_report(test_comprehensive_preload)
  
  expect_true(is.list(report))
  expect_true("summary" %in% names(report))
  expect_true("field_breakdown" %in% names(report))
  expect_true("issues" %in% names(report))
  
  expect_gt(report$summary$total_fields, 0)
  expect_true(report$summary$validation_status %in% c("VALID", "INVALID"))
})

test_that("Preload report handles empty data", {
  report <- create_preload_report(list())
  
  expect_true(is.list(report))
  expect_equal(report$summary$total_fields, 0)
})

test_that("Preload summary creation works", {
  summary <- create_preload_summary(test_basic_preload)
  
  expect_true(is.character(summary))
  expect_gt(nchar(summary), 0)
  expect_true(grepl("Preload Summary", summary))
})

test_that("Preload summary handles NULL input", {
  summary <- create_preload_summary(NULL)
  
  expect_equal(summary, "No preload data available")
})

# Integration Tests
test_that("JSON serialization and deserialization works", {
  # Test that preload configs can be saved and loaded as JSON
  json_string <- toJSON(test_comprehensive_preload, pretty = TRUE, auto_unbox = TRUE)
  loaded_config <- fromJSON(json_string, simplifyVector = TRUE)
  
  expect_equal(loaded_config$study_name, test_comprehensive_preload$study_name)
  expect_equal(loaded_config$species, test_comprehensive_preload$species)
  expect_equal(loaded_config$CDM_meta$trait, test_comprehensive_preload$CDM_meta$trait)
})

test_that("All template types can be created", {
  template_types <- c("gene_modulation", "compound_treatment", "disease_study", "model_characterization")
  
  for (template_type in template_types) {
    template <- create_preload_template(template_type)
    expect_true(is.list(template))
    expect_gt(length(template), 0)
  }
})

# Performance Tests
test_that("Validation performance is acceptable", {
  # Create a large preload configuration
  large_preload <- test_comprehensive_preload
  large_preload$multiple_selections$multiple_gene <- rep(paste0("GENE", 1:100), 10)
  
  start_time <- Sys.time()
  validation <- validate_preload_data(large_preload)
  end_time <- Sys.time()
  
  execution_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  expect_lt(execution_time, 1.0)  # Should complete within 1 second
})

# Run all tests
cat("Running preload functionality tests...\n")
test_results <- test_dir(".", reporter = "summary")
cat("Tests completed.\n")

# Print summary
if (length(test_results$failed) == 0) {
  cat("✅ All tests passed!\n")
} else {
  cat("❌ Some tests failed. Check output above for details.\n")
}

