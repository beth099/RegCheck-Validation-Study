# pull_sample_fulltexts.R
#
# Reads the sample selection Google Sheet, excludes rows where exclude == "Excluded",
# maps remaining DOIs to UIDs via data_key.xlsx, and copies the _fulltext.xml
# files from processed_articles/ into a new folder: sample_fulltexts/

library(here)
library(googlesheets4)
library(readxl)
library(dplyr)
library(purrr)

# ── 1. Read Google Sheet ──────────────────────────────────────────────────────

sheet_id <- "1KsfjMwSx4X6zIoJX1O5kwgtS-REAQxnDWw8NCGeCEFU"

# Sheet gid 1356597931 is the sample selection tab
# googlesheets4 uses sheet name or position; find it by gid
sheet_meta <- gs4_get(sheet_id)
sheet_names <- sheet_meta$sheets$name
sheet_gids  <- sheet_meta$sheets$id

target_sheet <- sheet_names[sheet_gids == 1356597931]

sample <- read_sheet(sheet_id, sheet = target_sheet)

# ── 2. Filter: keep rows where exclude is NOT "Excluded" ─────────────────────

doi_keep <- sample |>
  filter(is.na(exclude) | tolower(trimws(exclude)) != "excluded") |>
  pull(DOI) |>
  unique() |>
  na.omit()

cat("DOIs to pull:", length(doi_keep), "\n")

# ── 3. Load data_key to map DOI → UID ────────────────────────────────────────

data_key_path <- here("PsycArticles", "data_key (1).xlsx")
cat("Using data_key:", data_key_path, "\n")

data_key <- excel_sheets(data_key_path) |>
  map_dfr(\(s) read_xlsx(data_key_path, sheet = s)) |>
  select(UID, DOI)

uid_keep <- data_key |>
  filter(DOI %in% doi_keep) |>
  pull(UID)

cat("Matching UIDs found:", length(uid_keep), "\n")

# DOIs in sample but not in data_key (sanity check)
missing_doi <- setdiff(doi_keep, data_key$DOI)
if (length(missing_doi) > 0) {
  cat("Warning — DOIs not found in data_key:\n")
  cat(paste(" ", missing_doi), sep = "\n")
}

# ── 4. Copy _fulltext.xml files to sample_fulltexts/ ─────────────────────────

out_dir <- here("sample_fulltexts")
dir.create(out_dir, showWarnings = FALSE)

results <- map_dfr(uid_keep, function(uid) {
  src <- here("processed_articles", uid, paste0(uid, "_fulltext.xml"))

  if (!file.exists(src)) {
    return(tibble(uid = uid, status = "not_found"))
  }

  dest <- file.path(out_dir, paste0(uid, "_fulltext.xml"))
  file.copy(src, dest, overwrite = TRUE)
  tibble(uid = uid, status = "copied")
})

# ── 5. Summary ────────────────────────────────────────────────────────────────

cat("\nDone.\n")
cat("Copied:    ", sum(results$status == "copied"), "\n")
cat("Not found: ", sum(results$status == "not_found"), "\n")

if (any(results$status == "not_found")) {
  cat("UIDs not found in processed_articles:\n")
  cat(paste(" ", results$uid[results$status == "not_found"]), sep = "\n")
}
