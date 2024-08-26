library(tidyverse)

data <- read_csv("private_data/IPQlastitem_final_MERGED_LONG_CATEGORIES.csv")

results <- data %>% summarise_all(list(unique_values = ~length(unique(.)),
                                       na_count = ~sum(is.na(.)) + sum(. == ""))) %>% gather(variable, value);
write_csv(results, "derived_data/long_categories_summary.csv")

mapping <- read_csv("source_data/informal_cause_map.csv");

focus <- data %>% select(id,
                         time,
                         attributed_cause_1,
                         attributed_cause_2,
                         attributed_cause_3) %>%
    pivot_longer(cols=attributed_cause_1:attributed_cause_3, names_to="dummy") %>%
    select(-dummy);





