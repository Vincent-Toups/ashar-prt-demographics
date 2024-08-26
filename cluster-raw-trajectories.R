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
    data %>% select(id, time, Treatment, all_of(field)) %>%
        arrange(time) %>% pivot_wider(names_from=time, values_from=all_of(field));
}

raw_data <- read_csv("./derived_data/clinical_outcomes-d3.csv")
data <- raw_data %>%
    mutate(`Treatment`=c("PRT","Saline","SOC")[group]) %>%
    inner_join(raw_data %>% select(id) %>% distinct() %>%
               mutate(null_facet__=sample(seq(12),nrow(.),replace=T)),
               by="id") %>%
    remove_incomplete_trajectories() %>%
    make_vectors("bpi_intensity");

group_map <- raw_data %>% 
    mutate(`Treatment`=c("PRT","Saline","SOC")[group]) %>%
    select(id, Treatment) %>%
    distinct();

all_clusters <- kmeans(data %>% select(-id) %>% as.matrix(), 3);
aug_data <- data %>% mutate(cluster=all_clusters$cluster) %>%
    pivot_longer(`-1`:`12`, values_to="bpi_intensity", names_to="time") %>%
    mutate(time=as.numeric(time));

centers_df <- all_clusters$centers %>%
    as_tibble() %>% 
    mutate(center=row_number()) %>%
    pivot_longer(`-1`:`12`, values_to="bpi_intensity", names_to="time") %>%
    mutate(time=as.numeric(time));
for_mi_compare <- aug_data %>%
    select(id, cluster) %>%
    distinct() %>%
    inner_join(group_map,by="id") %>%
    mutate(group=c("SOC"=1,"Saline"=2,"PRT"=3)[Treatment]);

mi_with_group <- infotheo::mutinformation(for_mi_compare$cluster, for_mi_compare$group);

mi_with_mean_group <- block({
    df <- aug_data %>%
        inner_join(mean_groups <- raw_data %>%
                       group_by(id) %>%
                       summarize(mean_bpi_intensity=mean(bpi_intensity)) %>%
                       arrange(mean_bpi_intensity) %>%
                       mutate(mean_group=1+floor(seq(0,1, length.out=(nrow(.)))*2.9999)), by="id") %>%
        select(id, mean_group, cluster);
    infotheo::mutinformation(df$cluster, df$mean_group);
});

p <- ggplot(centers_df, aes(time, bpi_intensity)) +
    geom_line(aes(color=factor(center)),size=10) +
    geom_line(data=aug_data,
              mapping=aes(x=time,
                          y=bpi_intensity,
                          color=factor(cluster),
                          group=id),
              alpha=0.3) +
    labs(x="time",y="bpi_intensity",title=sprintf("naive clustering (mi w/ group = %0.2f, mi w/ mean = %0.2f)", mi_with_group, mi_with_mean_group));
ggsave(filename="figures/clustering_all_groups.png", plot=p);

