housevotes <- X1976_2024_house

housevotes <- housevotes %>% filter(party %in% c("DEMOCRAT","REPUBLICAN"))

election_totals <- housevotes %>%
  group_by(year, state, district) %>%
  summarise(
    dem_votes = sum(candidatevotes[party == "DEMOCRAT"], na.rm = TRUE),
    rep_votes = sum(candidatevotes[party == "REPUBLICAN"], na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    two_party_total = dem_votes + rep_votes,
    # Compute Democratic share of two‑party vote (set to NA if no votes at all)
    dem_two_party_share = if_else(two_party_total > 0,
                                  dem_votes / two_party_total,
                                  NA_real_),
    # Margin: Democratic share minus Republican share = 2*dem_share - 1
    two_party_margin = 2 * dem_two_party_share - 1
  )

members_1970sforward <- Hall_members %>% filter(congress >= 95)

# Create a named vector mapping ICPSR codes (as integers) to uppercase state names
icpsr_state_names <- c(
  "1"  = "CONNECTICUT",        "2"  = "MAINE",
  "3"  = "MASSACHUSETTS",      "4"  = "NEW HAMPSHIRE",
  "5"  = "RHODE ISLAND",       "6"  = "VERMONT",
  "11" = "DELAWARE",           "12" = "NEW JERSEY",
  "13" = "NEW YORK",           "14" = "PENNSYLVANIA",
  "21" = "ILLINOIS",           "22" = "INDIANA",
  "23" = "MICHIGAN",           "24" = "OHIO",
  "25" = "WISCONSIN",          "31" = "IOWA",
  "32" = "KANSAS",             "33" = "MINNESOTA",
  "34" = "MISSOURI",           "35" = "NEBRASKA",
  "36" = "NORTH DAKOTA",       "37" = "SOUTH DAKOTA",
  "40" = "VIRGINIA",           "41" = "ALABAMA",
  "42" = "ARKANSAS",           "43" = "FLORIDA",
  "44" = "GEORGIA",            "45" = "LOUISIANA",
  "46" = "MISSISSIPPI",        "47" = "NORTH CAROLINA",
  "48" = "SOUTH CAROLINA",     "49" = "TEXAS",
  "51" = "KENTUCKY",           "52" = "MARYLAND",
  "53" = "OKLAHOMA",           "54" = "TENNESSEE",
  "55" = "DISTRICT OF COLUMBIA", "56" = "WEST VIRGINIA",
  "61" = "ARIZONA",            "62" = "COLORADO",
  "63" = "IDAHO",              "64" = "MONTANA",
  "65" = "NEVADA",             "66" = "NEW MEXICO",
  "67" = "UTAH",               "68" = "WYOMING",
  "71" = "CALIFORNIA",         "72" = "OREGON",
  "73" = "WASHINGTON",         "81" = "ALASKA",
  "82" = "HAWAII"
)

# Function to convert numeric codes to state names
icpsr_to_state <- function(codes) {
  # Convert codes to character for safe indexing (handles both integer and factor input)
  char_codes <- as.character(codes)
  # Return mapped names, with NA for any unmapped codes
  unname(icpsr_state_names[char_codes])
}

members_1970sforward$state_name <- icpsr_to_state(members_1970sforward$state_icpsr)

election_totals$congress <- floor((election_totals$year - 1789) / 2) + 2

elections_and_ideology <- election_totals %>% left_join(members_1970sforward, 
                                                        by = c("state" = "state_name", 
                                                               "district" = "district_code",
                                                               "congress" = "congress"))

library(rdrobust)
ideology_party <- rdrobust(abs(elections_and_ideology$nominate_dim1), elections_and_ideology$two_party_margin)
summary(ideology_party)

rdplot(abs(elections_and_ideology$nominate_dim1), elections_and_ideology$two_party_margin)
