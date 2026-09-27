library(httr2)
library(purrr)
library(htmltools)
library(stringr)


MASTER_list <- read_csv("~/Desktop/RegCheck-Validation-Study/Sample_selection/feed_to_regcheck/MASTER_list.csv") |> 
  filter(is.na(exclude))

MASTER_list$osf_id <- str_extract(MASTER_list$registration_url, "(?<=osf\\.io/)[a-z0-9]{5}")

ids <- unique(na.omit(MASTER_list$osf_id)) # note: 4 osf ids are missing for preregistrations that had updated versions (we want to code the original, so I'll download those manually)


dir.create("OSF_preregs", showWarnings = FALSE)

get_json <- function(url) {
  request(url) |> req_retry(max_tries = 3) |> req_perform() |> resp_body_json()
}

save_prereg <- function(id) {
  reg  <- get_json(paste0("https://api.osf.io/v2/registrations/", id, "/"))
  att  <- reg$data$attributes
  resp <- att$registration_responses
  
  # Template questions, in order (question text + answer fields)
  schema_id <- reg$data$relationships$registration_schema$data$id
  blocks <- get_json(paste0("https://api.osf.io/v2/schemas/registrations/",
                            schema_id, "/schema_blocks/?page[size]=100"))$data
  
  body <- map_chr(blocks, function(b) {
    a <- b$attributes
    txt <- if (nzchar(a$display_text %||% "")) paste0("<h4>", htmlEscape(a$display_text), "</h4>") else ""
    key <- a$registration_response_key
    ans <- if (!is.null(key) && !is.null(resp[[key]])) {
      paste0("<p>", htmlEscape(paste(unlist(resp[[key]]), collapse = "; ")), "</p>")
    } else ""
    paste0(txt, ans)
  })
  
  html <- paste0("<html><head><meta charset='utf-8'><title>", htmlEscape(att$title),
                 "</title></head><body style='max-width:800px;margin:auto;font-family:sans-serif'>",
                 "<h2>", htmlEscape(att$title), "</h2>",
                 "<p>OSF ID: ", id, " | Registered: ", att$date_registered, "</p>",
                 paste(body, collapse = "\n"), "</body></html>")
  writeLines(html, file.path("OSF_preregs", paste0(id, ".html")))
  
  # Attached files as zip
  request(paste0("https://files.osf.io/v1/resources/", id, "/providers/osfstorage/?zip=")) |>
    req_perform(path = file.path("OSF_preregs", paste0(id, "_files.zip")))
  
  Sys.sleep(1)  # be gentle with the OSF API
}

results <- map(ids, safely(save_prereg))
failed  <- ids[map_lgl(results, ~ !is.null(.x$error))]
failed  # check these manually (withdrawn, embargoed, typo'd IDs, etc.)

##

ids <- c("4gtkn", "zbmun", "twy6c","yfz9r", "n36cu")  # your 3 OSF IDs + 2 that failed the first time

out_dir <- here::here("OSF_preregs")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

get_json <- function(url) {
  request(url) |> req_retry(max_tries = 3) |> req_perform() |> resp_body_json()
}

save_prereg_original <- function(id) {
  reg <- get_json(paste0("https://api.osf.io/v2/registrations/", id, "/"))
  att <- reg$data$attributes

  # Original version of the answers (earliest schema response)
  sr <- get_json(paste0("https://api.osf.io/v2/registrations/", id,
                        "/schema_responses/?page[size]=100"))$data
  n_versions <- length(sr)
  if (n_versions > 0) {
    created <- map_chr(sr, ~ .x$attributes$date_created)
    resp <- sr[[order(created)[1]]]$attributes$revision_responses
  } else {
    resp <- att$registration_responses
  }

  # Template questions, in order
  schema_id <- reg$data$relationships$registration_schema$data$id
  blocks <- get_json(paste0("https://api.osf.io/v2/schemas/registrations/",
                            schema_id, "/schema_blocks/?page[size]=100"))$data

  body <- map_chr(blocks, function(b) {
    a <- b$attributes
    txt <- if (nzchar(a$display_text %||% "")) paste0("<h4>", htmlEscape(a$display_text), "</h4>") else ""
    key <- a$registration_response_key
    ans <- if (!is.null(key) && !is.null(resp[[key]])) {
      paste0("<p>", htmlEscape(paste(unlist(resp[[key]]), collapse = "; ")), "</p>")
    } else ""
    paste0(txt, ans)
  })

  html <- paste0("<html><head><meta charset='utf-8'><title>", htmlEscape(att$title),
                 "</title></head><body style='max-width:800px;margin:auto;font-family:sans-serif'>",
                 "<h2>", htmlEscape(att$title), "</h2>",
                 "<p>OSF ID: ", id, " | Registered: ", att$date_registered,
                 " | Showing: original version (", n_versions, " version(s) on OSF)</p>",
                 paste(body, collapse = "\n"), "</body></html>")
  writeLines(html, file.path(out_dir, paste0(id, ".html")))

  # Attached files
  request(paste0("https://files.osf.io/v1/resources/", id, "/providers/osfstorage/?zip=")) |>
    req_perform(path = file.path(out_dir, paste0(id, "_files.zip")))

  Sys.sleep(1)
}

results <- map(ids, safely(save_prereg_original))
map(results, "error")  # NULL = success; anything else shows what went wrong
list.files(out_dir)
