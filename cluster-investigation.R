library(tidyverse);
library(gbm);
library(tidyverse)
library(ggplot2)
library(dplyr)
library(scales)
source("utilities.R");

cluster_step(read_csv("./derived_data/clinical_outcomes-d3.csv"),
             "SOC",
             "bpi_intensity")

conditions <- c("SOC","Saline","PRT");
variables <- c("pain_avg", "bpi_intensity", "bpi_interference");

d <- read_csv("./derived_data/clinical_outcomes-d3.csv");
apply(expand.grid(conditions, variables), 1, function(row){
    v <- as.list(row);
    print(v);
    tryCatch(expr=
                 cluster_step(d,v$Var1, v$Var2));
})

system("cat html/*.html > html/all.html");
