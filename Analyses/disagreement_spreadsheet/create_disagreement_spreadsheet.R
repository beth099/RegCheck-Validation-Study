# Set up 
# Load packages

library(readr)
library(tidyverse)

# Read in cleaned data
data_cleaned <- read_csv("~/Desktop/RegCheck-Validation-Study/Data/prereg_deviations_data_cleaned.csv") # articles that may have been coded but should be excluded
MASTER_list <- read_csv("~/Desktop/RegCheck-Validation-Study/Sample_selection/feed_to_regcheck/MASTER_list.csv") |>  # for matching DOIs and prereg links
  filter(is.na(exclude)) |> 
  rename(article_num = article_number)
  
# Need to load in round 2 of coding once we have it.

options(scipen = 999) #turn off scientific notation
options(digits = 2)

# Step 1: Pivot the data wider
data_long <- data_cleaned %>%
  select(
    article_num, coder, study_num,
    matches("^(hypothesis|datas|inex|samplesize|manvars|measurvars|stats|transf|missd)_(prereg|paper|notreg|deviation|concerns|conf|comments)$")
  ) %>%
  pivot_longer(
    cols = -c(article_num, coder, study_num),
    names_to  = c("dimension", ".value"),
    names_pattern = "^(.+?)_(prereg|paper|notreg|deviation|concerns|conf|comments)$"
  )


# Step 2: Convert to pairwise comparisons
# Get all unique coder pairs
coders <- unique(data_long$coder)
coder_pairs <- combn(sort(coders), 2, simplify = FALSE)  # sort alphabetically (so that we don't get both BC_JC and JC_BC later)

# Build one pairwise row per article_num x dimension x pair
data_pairs <- map_dfr(coder_pairs, function(pair) {
  c1 <- pair[1]; c2 <- pair[2]
  
  left  <- data_long %>% filter(coder == c1) %>%
    select(article_num, study_num, dimension, 
           prereg_c1 = prereg, 
           paper_c1 = paper,
           deviation_c1 = deviation, 
           concerns_c1 = concerns,
           conf_c1 = conf, 
           comments_c1 = comments)
  
  right <- data_long %>% filter(coder == c2) %>%
    select(article_num, dimension,
           prereg_c2 = prereg, 
           paper_c2 = paper,
           deviation_c2 = deviation, 
           concerns_c2 = concerns,
           conf_c2 = conf, 
           comments_c2 = comments)
  
  left %>%
    inner_join(right, by = c("article_num", "dimension")) %>%
    mutate(
      coder1 = c1,
      coder2 = c2,
      coder_pair       = paste(c1, c2, sep = "_"),
      deviation_agree  = as.integer(
        deviation_c1 == deviation_c2 |
          (str_detect(deviation_c1, "vague") & str_detect(deviation_c2, "vague")) |
          (is.na(deviation_c1) & is.na(deviation_c2))
      )
    )
})



#---------------------------
# Pivot to get disagreements
disagreements_to_resolve <- data_pairs %>%
  filter(deviation_agree == 0 | is.na(deviation_agree)) |> 
  filter(!(is.na(deviation_c1) & is.na(deviation_c2))) |> 
  select(-c(deviation_agree, coder1, coder2)) |> 
  select(coder_pair, article_num, study_num, everything()) |> 
  mutate(final_deviation_decision = "")


# Add paper and prereg links
disagreements_to_resolve <- disagreements_to_resolve %>%
  left_join(
    MASTER_list %>% select(article_num, doi_link, registration_url),
    by = "article_num"
  ) |> 
  relocate(doi_link, registration_url, .after = article_num)


write_csv(disagreements_to_resolve, "disagreement_spreadsheet/disagreements_to_resolve.csv")
