#!/usr/bin/env Rscript

# --- 1. Dependencies ---
library(dplyr)
library(lubridate)
library(stringr) 

# --- 2. Configuration & Setup ---
input_dir <- "./Input"
output_dir <- "./Output"
output_file <- file.path(output_dir, "output.csv")

if (!dir.exists(output_dir)) dir.create(output_dir)

# Find files
xml_files <- list.files(path = input_dir, pattern = "export\\.xml$", recursive = TRUE, full.names = TRUE)

# Initialize CSV with headers
headers <- data.frame(type=character(), startDate=character(), endDate=character(), 
                     value=character(), unit=character(), sourceName=character(),
                     source_directory=character())
write.csv(headers, output_file, row.names = FALSE)

# --- 3. Regex Extraction Function ---
# This helper function extracts the value of an attribute from an XML string
extract_attr <- function(lines, attr_name) {
  pattern <- paste0(attr_name, '="([^"]*)"')
  str_match(lines, pattern)[,2]
}

process_health_regex <- function(file_path) {
  message(paste("Processing file:", file_path))
  parent_dir <- basename(dirname(file_path))
  
  # 1. Read lines
  raw_lines <- readLines(file_path, warn = FALSE)
  
  # 2. Filter for Huawei and specific types using string matching
  is_huawei <- str_detect(raw_lines, fixed('sourceName="HUAWEI Health: Europe"'))
  is_target_type <- str_detect(raw_lines, 'HKQuantityTypeIdentifier(HeartRate|StepCount)')
  
  relevant_lines <- raw_lines[is_huawei & is_target_type]
  rm(raw_lines) # Immediate memory cleanup
  
  if (length(relevant_lines) == 0) return(0)
  
  # 3. Extract data using Regex (No XML parsing = No depth errors)
  df_clean <- data.frame(
    type = extract_attr(relevant_lines, "type"),
    startDate = extract_attr(relevant_lines, "startDate"),
    endDate = extract_attr(relevant_lines, "endDate"),
    value = as.numeric(extract_attr(relevant_lines, "value")),
    unit = extract_attr(relevant_lines, "unit"),
    sourceName = "HUAWEI Health: Europe",
    source_directory = parent_dir,
    stringsAsFactors = FALSE
  )
  
  # 4. Clean up formatting
  df_clean <- df_clean %>%
    mutate(
      startDate = ymd_hms(startDate),
      endDate = ymd_hms(endDate),
      type = case_when(
        type == "HKQuantityTypeIdentifierHeartRate" ~ "HeartRate",
        type == "HKQuantityTypeIdentifierStepCount" ~ "Steps",
        TRUE ~ type
      )
    )
  
  # 5. Append to CSV
  write.table(df_clean, output_file, sep = ",", col.names = FALSE, 
              append = TRUE, row.names = FALSE, qmethod = "double")
  
  return(nrow(df_clean))
}

# --- 4. Main Loop ---
total_records <- 0
for (f in xml_files) {
  count <- process_health_regex(f)
  total_records <- total_records + count
  gc() # Garbage collection
}

cat("\n==========================================\n")
cat(paste("Finished! Total records processed:", total_records, "\n"))
cat("==========================================\n")
