library(tidyverse);

data <- read_csv("derived_data/clinical_outcomes-d3.csv") %>%
    select(id, group, bpi_intensity, time) %>%
    pivot_wider(id_cols=c("id","group"),names_from="time", values_from="bpi_intensity");

write_csv(data, "derived_data/outcome_vectors.csv");



