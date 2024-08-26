library(tidyverse)
library(ggplot2)
library(dplyr)
library(scales)

data <- read_csv("./derived_data/clinical_outcomes-d3.csv") %>%
    mutate(`Treatment`=c("PRT","Saline","SOC")[group]) %>%
    inner_join(data %>% select(id) %>% distinct() %>%
               mutate(null_facet__=sample(seq(12),nrow(.),replace=T)),
               by="id");

remove_incomplete_trajectories <- function(data){
    counts <- data %>% group_by(id) %>% tally();
    max_count <- counts %>% pull(n) %>% max();
    data %>%
        inner_join(counts, by="id") %>%
        filter(n==max_count) %>%
        select(-n);
}

make_vectors <- function(data, field){
    data %>% select(id, time, all_of(field)) %>%
        arrange(time) %>% pivot_wider(names_from=time, values_from=all_of(field));
}

plot_trajectories <- function(data, column_to_plot, output_filename, arrange_columns = c("null_facet__")) {
  data <- data %>%
      group_by(id) %>%
      mutate(across(c(pain_avg, bpi_intensity, bpi_interference, odi), scales::rescale, to = c(0, 1))) %>%
      ungroup()

  dodge_amount <- 1.1;
  data <-do.call(rbind,  Map(function(sub){
      rank <- sub %>% filter(time>=3 & time <=6) %>% group_by(id) %>% summarize(sum_post=sum(!!sym(column_to_plot)));
      sub %>%
          inner_join(sub %>%
                     select(id) %>%
                     distinct() %>%
                     inner_join(rank,by="id") %>%
                     arrange(sum_post) %>%
                     select(-sum_post) %>%
                     mutate(y_dodge = row_number() * dodge_amount), by="id") 
  }, data %>%
     group_by_(arrange_columns) %>% group_split()))

  p <- ggplot(data, aes(x = time, y = !!sym(column_to_plot) + y_dodge, group = id, color = Treatment)) +
      geom_line() +
      facet_wrap(as.formula(paste0("~ paste0(",paste(sprintf("as.character(%s)",arrange_columns),collapse=", "),")")));

  path_parts <- tools::file_path_sans_ext(output_filename)
  file_extension <- tools::file_ext(output_filename)
  arrange_columns_str <- paste(arrange_columns, collapse = "_")
  modified_filename <- paste0(path_parts, "_", arrange_columns_str, "_", column_to_plot, ".", file_extension)
  ggsave(modified_filename, p)
  print(p)
  p
}
## plot_trajectories <- function(data, column_to_plot, output_filename, arrange_columns = c("id")) {
##     arrange_expr <- syms(arrange_columns)
    
##     data <- data %>%
##         inner_join(data %>%
##                    select(all_of(arrange_columns)) %>%
##                    distinct() %>%
##                    arrange_(arrange_columns) %>%
##                    mutate(y_offset = seq(nrow(.))), by = all_of(arrange_columns)) %>%
##         group_by(id) %>%
##         mutate(across(c(pain_avg, bpi_intensity, bpi_interference, odi), scales::rescale, to = c(0, 1))) %>%
##         ungroup()

##     facets <- 12
##     p <- ggplot(data, aes(time, !!sym(column_to_plot) + y_offset / facets)) +
##         geom_line(aes(group = id, color = Treatment)) +
##         facet_wrap(~ y_offset %% facets)

##     path_parts <- tools::file_path_sans_ext(output_filename)
##     file_extension <- tools::file_ext(output_filename)
##     y_offset_columns <- paste(arrange_columns, collapse="_")
##     modified_filename <- paste0(path_parts, "_", y_offset_columns, "_", column_to_plot, ".", file_extension)
##     ggsave(modified_filename, p)
##     print(p)
##     p
## }



do_kmeans <- function(data, variable, n=4){
    vdata <- remove_incomplete_trajectories(data) %>%
        make_vectors(variable);
    cc <- kmeans(vdata %>%
                              select(-id) %>%
                              as.matrix(),
                 centers=n)$cluster;
    clustering <- vdata %>% select(id);
    clustering$cluster <- cc;
    print(clustering);
    data <- data %>% select(-cluster) %>% inner_join(clustering, by="id");
    data  
}

variables_to_plot <- c("bpi_intensity", "bpi_interference", "pain_avg")

for (var in variables_to_plot) {
  plot_trajectories(data, var, "figures/trajectories.png",arrange_columns="Treatment")
  plot_trajectories(do_kmeans(data, var, 10), var, "figures/trajectories.jpeg", arrange_columns = c("Treatment", "cluster"))
}
