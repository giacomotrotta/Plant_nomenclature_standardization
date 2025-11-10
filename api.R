# ==========================================================
#  Plant Name Normalizer API (POWO/WCVP) - LOCAL
# ==========================================================

library(plumber)
library(TNRS)
library(dplyr)
library(stringr)
library(jsonlite)

# ---------- Helper: cleaning del nome ----------
clean_name <- function(x) {
  x %>%
    str_squish() %>%
    str_replace_all("\\s+", " ") %>%
    str_replace_all("\\b(cf\\.|aff\\.|nr\\.|sp\\.|spp\\.|group|gr\\.)\\b", "") %>%
    str_replace_all("[?]", "") %>%
    str_squish()
}

# ---------- Core function ----------
standardize_names_powo <- function(x,
                                   source = "wcvp",
                                   min_score_auto = 0.9,
                                   min_score_keep = 0.8) {

  df_in <- tibble(
    submitted    = x,
    cleaned_name = clean_name(x)
  )

  uniq <- unique(df_in$cleaned_name)

  if (length(uniq) == 0) {
    return(df_in %>% mutate(
      matched_name = NA_character_,
      accepted_name = NA_character_,
      accepted_author = NA_character_,
      family = NA_character_,
      powo_uri = NA_character_,
      taxonomic_status = NA_character_,
      score = NA_real_,
      match_type = "unresolved_no_match"
    ))
  }

  tnrs_raw <- TNRS(uniq, sources = source)

  best <- tnrs_raw %>%
    group_by(Name_submitted) %>%
    slice_max(order_by = Overall_score, n = 1, with_ties = FALSE) %>%
    ungroup()

  lk <- best %>%
    transmute(
      cleaned_name      = Name_submitted,
      matched_name      = Name_matched,
      accepted_name     = Accepted_name,
      accepted_author   = Accepted_name_author,
      family            = Name_matched_accepted_family,
      powo_uri          = Name_matched_url,
      taxonomic_status  = Taxonomic_status,
      score             = Overall_score
    )

  df_in %>%
    left_join(lk, by = "cleaned_name") %>%
    mutate(
      match_type = case_when(
        is.na(score) ~ "unresolved_no_match",
        score < min_score_keep ~ "unresolved_low_score",
        taxonomic_status == "Synonym" & !is.na(accepted_name) ~ "synonym_to_accepted",
        taxonomic_status == "Accepted" & score >= min_score_auto ~ "exact_or_fuzzy_accepted",
        TRUE ~ "fuzzy_needs_review"
      )
    )
}

# ---------- API definition ----------
#* @apiTitle Plant Name Normalizer API

#* CORS per richieste dal frontend
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  plumber::forward()
}

#* Normalizza una lista di nomi botanici
#* Invia JSON: { "names": ["Quercus robur", "Fagus sylvaticaa"] }
#* @post /normalize
#* @serializer json
function(req, res) {

  body_raw <- req$postBody

  if (is.null(body_raw) || body_raw == "") {
    res$status <- 400
    return(list(
      error = "Empty request body. Send JSON: {\"names\": [\"Quercus robur\", \"Fagus sylvaticaa\"]}"
    ))
  }

  parsed <- tryCatch(
    jsonlite::fromJSON(body_raw),
    error = function(e) NULL
  )

  if (is.null(parsed) || is.null(parsed$names)) {
    res$status <- 400
    return(list(
      error = "Invalid JSON. Expected: {\"names\": [\"Quercus robur\", \"Fagus sylvaticaa\"]}"
    ))
  }

  names_vec <- as.character(parsed$names)

  result <- tryCatch(
    standardize_names_powo(names_vec),
    error = function(e) {
      res$status <- 500
      list(error = paste("Internal error:", e$message))
    }
  )

  return(result)
}
