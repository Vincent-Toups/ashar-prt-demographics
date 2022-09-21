library(tidyverse);

to_table <- function(summary_df){
    out <- list();
    group_names <- c("PRT","Saline","SOC");
    apply(summary_df, 1, function(row){        
        out[group_names[[row[["group"]]]]] <<- row[["n"]];
    })
    out 
}

demographics <- read_csv("./source_data/demographics.csv") %>%
    group_by(group) %>% tally() %>% to_table();


cat(sprintf("There were %d patients in the PRT group, %d in the Saline group, and %d received the standard of care.", demographics[["PRT"]], demographics[["Saline"]], demographics[["SOC"]]),
    file="derived_data/patient-count.fragment.Rmd");

