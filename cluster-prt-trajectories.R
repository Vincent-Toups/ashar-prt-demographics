library(tidyverse)
library(ggplot2)
library(dplyr)
library(scales)
source("utilities.R");

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

raw_data <- read_csv("./derived_data/clinical_outcomes-d3.csv")
data <- raw_data %>%
    mutate(`Treatment`=c("PRT","Saline","SOC")[group]) %>%
    filter(Treatment=='PRT') %>%
    select(-Treatment) %>% 
    inner_join(raw_data %>% select(id) %>% distinct() %>%
               mutate(null_facet__=sample(seq(12),nrow(.),replace=T)),
               by="id") %>%
    remove_incomplete_trajectories() %>%
    make_vectors("bpi_intensity");


all_clusters <- kmeans(data %>% select(-id) %>% as.matrix(), 3);
aug_data <- data %>% mutate(cluster=all_clusters$cluster) %>%
    pivot_longer(`-1`:`12`, values_to="bpi_intensity", names_to="time") %>%
    mutate(time=as.numeric(time));

centers_df <- all_clusters$centers %>%
    as_tibble() %>% 
    mutate(center=row_number()) %>%
    pivot_longer(`-1`:`12`, values_to="bpi_intensity", names_to="time") %>%
    mutate(time=as.numeric(time));

p <- ggplot(centers_df, aes(time, bpi_intensity)) +
    geom_line(aes(color=factor(center)),size=10) +
    geom_line(data=aug_data,
              mapping=aes(x=time,
                          y=bpi_intensity,
                          color=factor(cluster),
                          group=id),
              alpha=0.3) +
    labs(x="time",y="bpi_intensity",title=sprintf("naive clustering (mi w/ group = %0.2f, mi w/ mean = %0.2f)", mi_with_group, mi_with_mean_group));
ggsave(filename="figures/clustering_prt.png", plot=p);

data <- raw_data %>%
    mutate(`Treatment`=c("PRT","Saline","SOC")[group]) %>%
    filter(Treatment=='PRT') %>%
    select(-Treatment) %>% 
    inner_join(raw_data %>% select(id) %>% distinct() %>%
               mutate(null_facet__=sample(seq(12),nrow(.),replace=T)),
               by="id") %>%
    remove_incomplete_trajectories() %>%
    group_by(id) %>%
    mutate(bpi_intensity = scales::rescale(bpi_intensity,c(0,1))) %>%
    ungroup() %>%
    make_vectors("bpi_intensity");

all_clusters <- kmeans(data %>% select(-id) %>% as.matrix(), 3);
aug_data <- data %>% mutate(cluster=all_clusters$cluster) %>%
    pivot_longer(`-1`:`12`, values_to="bpi_intensity", names_to="time") %>%
    mutate(time=as.numeric(time));

centers_df <- all_clusters$centers %>%
    as_tibble() %>% 
    mutate(center=row_number()) %>%
    pivot_longer(`-1`:`12`, values_to="bpi_intensity", names_to="time") %>%
    mutate(time=as.numeric(time));

p <- ggplot(centers_df, aes(time, bpi_intensity)) +
    geom_line(aes(color=factor(center)),size=10) +
    geom_line(data=aug_data,
              mapping=aes(x=time,
                          y=bpi_intensity,
                          color=factor(cluster),
                          group=id),
              alpha=0.3) +
    labs(x="time",y="bpi_intensity",title=sprintf("naive clustering (mi w/ group = %0.2f, mi w/ mean = %0.2f)", mi_with_group, mi_with_mean_group));
ggsave(filename="figures/clustering_prt_norm.png", plot=p);
