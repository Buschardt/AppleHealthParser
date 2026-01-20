#!/usr/bin/env Rscript

# --- 1. Dependencies ---

library(xml2)
library(dplyr)
library(lubridate)

# --- 2. Locate Files ---
# Find all export.xml files inside ./Input and its subdirectories
input_dir <- "./Input"
if (!dir.exists(input_dir)) {
  stop(paste("Directory", input_dir, "does not exist. Please create it and add your data."))
}

xml_files <- list.files(path = input_dir, 
                        pattern = "export\\.xml$", 
                        recursive = TRUE, 
                        full.names = TRUE)

if (length(xml_files) == 0) {
  stop("No export.xml files found in ./Input/ or its subfolders.")
}

message(paste("Found", length(xml_files), "file(s). Processing..."))

# --- 3. Process Files & Parse XML ---
process_health_xml <- function(file_path) {
  message(paste("Reading:", file_path))
  
  # Load the XML file into memory
  doc <- read_xml(file_path)
  
  # Find all 'Record' nodes (where the data lives)
  # We use an XPath query to pre-filter only the types we want to save memory
  # Note: Apple Health uses strict type names
  xpath_query <- paste0(
    "//Record[@type='HKQuantityTypeIdentifierHeartRate'] | ",
    "//Record[@type='HKQuantityTypeIdentifierStepCount']"
  )
  
  records <- xml_find_all(doc, xpath_query)
  
  if (length(records) == 0) {
    warning(paste("No heart rate or step data found in", file_path))
    return(NULL)
  }
  
  # Extract attributes (value, type, startDate, etc.) into a data frame
  # xml_attrs returns a list; bind_rows turns it into a tidy tibble
  df <- bind_rows(lapply(xml_attrs(records), function(x) as.list(x)))
  
  # --- 4. Clean and Format Data ---
  df_clean <- df %>%
    select(type, startDate, value, unit) %>% # Select only relevant columns
    mutate(
      value = as.numeric(value),
      startDate = ymd_hms(startDate), # Parse ISO8601 dates
      source_file = basename(file_path) # Keep track of which file this came from
    ) %>%
    # Simplify type names for readability
    mutate(type = case_when(
      type == "HKQuantityTypeIdentifierHeartRate" ~ "HeartRate",
      type == "HKQuantityTypeIdentifierStepCount" ~ "Steps",
      TRUE ~ type
    ))
  
  return(df_clean)
}

# Apply the function to all found files and combine results
final_df <- bind_rows(lapply(xml_files, process_health_xml))

# --- 5. Print Result ---
cat("\n--- Processing Complete ---\n")
print(head(final_df, 10)) # Print first 10 rows
cat(paste("\nTotal records loaded:", nrow(final_df), "\n"))
  
