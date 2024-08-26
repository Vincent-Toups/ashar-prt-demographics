library(tidyverse);
library(gbm);
library(tidyverse)
library(ggplot2)
library(dplyr)
library(scales)


slurp <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("File does not exist.")
  }
  lines <- readLines(file_path)
  content <- paste(lines, collapse = "\n")
  return(content)
}

na.replace <- function(v, with){
    v[is.na(v)] <- with;
    v
}

ensure_directory_exists <- function(dir_path) {
  if (!file.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }
}

slurp <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("File does not exist.")
  }
  lines <- readLines(file_path)
  content <- paste(lines, collapse = "\n")
  return(content)
}

block <- gtools::defmacro(bl,expr=(function()bl)());

summarize_df <- function(df) {
  df %>%
      summarise(
          n=sum(rep(1,length(row_number()))),
          across(where(is.numeric), mean),
          across(where(is.character), 
                 ~paste(paste0(names(sort(table(.), decreasing = TRUE)[1])," "), 
                        round(100 * max(table(.)) / length(.), 2), "%", sep = ""))
      )
}


tidy_demo_data <- function(df) {
  df %>% 
    mutate(
      ethnicity = recode(ethnicity, 
                         `1` = "Nat.Am./Al", 
                         `2` = "Asn/Pac.Isl.", 
                         `3` = "Blk", 
                         `4` = "Wht", 
                         .default = "Other"),
      hispanic = if_else(hispanic == 1, "Hsp", "NonHsp"),
      married_or_living_as_marri = if_else(married_or_living_as_marri == 1, "Mrd", "NonMrd"),
      gender = recode(gender, 
                      `1` = "Male", 
                      `2` = "Female", 
                      .default = "Other"),
      handedness = recode(handedness, 
                          `1` = "R", 
                          `2` = "L", 
                          .default = "A")
    )
}

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

maybe_rescale <- function(data, column, rescale=T){
    if(!rescale){
        data;
    } else {
        data %>% group_by(id) %>%
            mutate(across(column, ~ scales::rescale(., to=c(0,1)))) %>% 
            ungroup();
    }
}

cluster_step <- function(raw_data, experimental_condition, variable, rescale=T){
    data <- raw_data %>%
        mutate(`Treatment`=c("PRT","Saline","SOC")[group]) %>%
        filter(Treatment==experimental_condition) %>%
        select(-Treatment) %>% 
        inner_join(raw_data %>% select(id) %>% distinct() %>%
                   mutate(null_facet__=sample(seq(12),nrow(.),replace=T)),
                   by="id") %>%
        remove_incomplete_trajectories() %>%
        maybe_rescale(variable, rescale) %>%
        make_vectors(variable);

    all_clusters <- kmeans(data %>% select(-id) %>% as.matrix(), 3);
    aug_data <- data %>% mutate(cluster=all_clusters$cluster) %>%
        pivot_longer(`-1`:`12`, values_to=variable, names_to="time") %>%
        mutate(time=as.numeric(time));

    centers_df <- all_clusters$centers %>%
        as_tibble() %>% 
        mutate(center=row_number()) %>%
        pivot_longer(`-1`:`12`, values_to=variable, names_to="time") %>%
        mutate(time=as.numeric(time));

    p <- ggplot(centers_df, aes(time, .data[[variable]])) +
        geom_line(aes(color=factor(center)),size=10) +
        geom_line(data=aug_data,
                  mapping=aes_string(x="time",
                              y=variable,
                              color="factor(cluster)",
                              group="id"),
                  alpha=0.3) +
        labs(x="time",y=variable,title=sprintf("%s clusters", experimental_condition));
    print(p);
    ggsave(filename=sprintf("figures/clustering_%s_%s.png", experimental_condition, variable), plot=p);
    clustering <- aug_data %>% select(id, cluster) %>% distinct() %>% arrange(id, cluster);

    sink(sprintf("derived_data/clustering_characterization_%s_%s.txt",
             experimental_condition,
             variable));

    demographics <- read_csv("source_data/demographics.csv") %>%
        tidy_demo_data() %>% 
        inner_join(clustering, by="id") %>% group_by(cluster) %>%
        summarize_df() %>% t() %>% print();

    sink();

    ensure_directory_exists("markdown");
    ensure_directory_exists("html");

    catx <- function(...){
        cat(..., file=sprintf("markdown/clustering_%s_%s.md", experimental_condition, variable));
    }

    catx("",append=FALSE);
    catx(sprintf("Condition %s, Variable %s", experimental_condition, variable), sep="\n");
    catx(sprintf("
<img src=\"../figures/clustering_%s_%s.png\" alt=\"drawing\" width=\"600\"/>\n\n
```
%s
```", experimental_condition, variable, slurp(sprintf("derived_data/clustering_characterization_%s_%s.txt",
                                                      experimental_condition,
                                                      variable))));

    system(sprintf("pandoc -i %s -o %s", sprintf("markdown/clustering_%s_%s.md", experimental_condition, variable),
           sprintf("html/clustering_%s_%s.html", experimental_condition, variable)))

    list(clustering, demographics, data);
}

cluster_step <- function(raw_data, experimental_condition, variable, rescale=T){

    print(experimental_condition != "all")

    data <- if(experimental_condition != "all"){
                raw_data %>%
                mutate(`Treatment`=c("PRT","Saline","SOC")[group]) %>%
                    filter(Treatment == experimental_condition); 
            } else {
                raw_data %>%
                mutate(`Treatment`=c("PRT","Saline","SOC")[group])
            }
  # Preprocess data
  data <- data %>% 
    select(-Treatment) %>%
    inner_join(raw_data %>% select(id) %>% distinct() %>%
               mutate(null_facet__=sample(seq(12),nrow(.),replace=T)),
               by="id") %>%
    remove_incomplete_trajectories() %>%
    maybe_rescale(variable, rescale) %>%
    make_vectors(variable);

  # Perform clustering
  all_clusters <- kmeans(data %>% select(-id) %>% as.matrix(), 3);
  aug_data <- data %>% mutate(cluster=all_clusters$cluster) %>%
    pivot_longer(`-1`:`12`, values_to=variable, names_to="time") %>%
    mutate(time=as.numeric(time));

  centers_df <- all_clusters$centers %>%
    as_tibble() %>% 
    mutate(center=row_number()) %>%
    pivot_longer(`-1`:`12`, values_to=variable, names_to="time") %>%
    mutate(time=as.numeric(time));

  # Update plot title based on experimental_condition
  plot_title <- if(experimental_condition != "all") {
    sprintf("%s clusters", experimental_condition)
  } else {
    "All Conditions Clusters"
  }

  # Create and save plot
  p <- ggplot(centers_df, aes(time, .data[[variable]])) +
    geom_line(aes(color=factor(center)),size=10) +
    geom_line(data=aug_data,
              mapping=aes_string(x="time",
                                 y=variable,
                                 color="factor(cluster)",
                                 group="id"),
              alpha=0.3) +
    labs(x="time",y=variable,title=plot_title);
  
  print(p);
  
  ggsave(filename=sprintf("figures/clustering_%s_%s.png", experimental_condition, variable), plot=p);
  
  # ... rest of your code for saving and exporting results
    clustering <- aug_data %>% select(id, cluster) %>% distinct() %>% arrange(id, cluster);

    sink(sprintf("derived_data/clustering_characterization_%s_%s.txt",
             experimental_condition,
             variable));

    demographics <- read_csv("source_data/demographics.csv") %>%
        tidy_demo_data() %>% 
        inner_join(clustering, by="id") %>% group_by(cluster) %>%
        summarize_df() %>% t() %>% print();

    sink();

    ensure_directory_exists("markdown");
    ensure_directory_exists("html");

    catx <- function(...){
        cat(..., file=sprintf("markdown/clustering_%s_%s.md", experimental_condition, variable));
    }

    catx("",append=FALSE);
    catx(sprintf("Condition %s, Variable %s", experimental_condition, variable), sep="\n");
    catx(sprintf("
<img src=\"../figures/clustering_%s_%s.png\" alt=\"drawing\" width=\"600\"/>\n\n
```
%s
```", experimental_condition, variable, slurp(sprintf("derived_data/clustering_characterization_%s_%s.txt",
                                                      experimental_condition,
                                                      variable))));

    system(sprintf("pandoc -i %s -o %s", sprintf("markdown/clustering_%s_%s.md", experimental_condition, variable),
           sprintf("html/clustering_%s_%s.html", experimental_condition, variable)))

    list(clustering, demographics, data);

}
