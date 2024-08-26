library(tidyverse);
source("utilities.R");
library(gbm);


set.seed(123)
d <- read_csv("./derived_data/clinical_outcomes-d3.csv");
r <- cluster_step(d, "all", "bpi_interference");
clustering <- r[[1]];
summary <- r[[2]];
vectors <- r[[3]];
bump_cluster <- 1;
worsen_cluster <- 2;
improve_cluster <- 3;

demographics <- read_csv("/home/rstudio/work/source_data/demographics.csv") %>%
    tidy_demo_data() %>%
    inner_join(clustering, by="id");

average_bump <- vectors %>% inner_join(clustering, by="id") %>%
    filter(cluster==bump_cluster) %>% group_by(cluster) %>%
    summarize(across(`-1`:`12`, mean)) %>% select(-cluster);
average_worsen <- average_bump <- vectors %>% inner_join(clustering, by="id") %>%
    filter(cluster==worsen_cluster) %>% group_by(cluster) %>%
    summarize(across(`-1`:`12`, mean)) %>% select(-cluster);
average_improve <- average_bump <- vectors %>% inner_join(clustering, by="id") %>%
    filter(cluster==improve_cluster) %>% group_by(cluster) %>%
    summarize(across(`-1`:`12`, mean)) %>% select(-cluster);


linear_optimize <- function(vec1, vec2, vec3, target_vec) {
  objective_function <- function(weights) {
    pred_vec <- weights[1] * vec1 + weights[2] * vec2 + weights[3] * vec3
    error <- sum((pred_vec - target_vec)^2)
    return(error)
  }
  
  initial_weights <- c(0.33, 0.33, 0.34)
  opt_result <- optim(par = initial_weights,
                      fn = objective_function,
                      method = "L-BFGS-B",
                      lower = c(-1, -1, -1),
                      upper = c(1, 1, 1))
  print(opt_result$par)
  return(opt_result$par)
}


vectors_proj <- vectors %>% rowwise() %>%
    mutate(abc=list(linear_optimize(average_bump, average_worsen, average_improve,
                                    c(`-1`,`0`,`1`,`2`,`3`,`6`,`12`))),
           cbump=sum(c(`-1`,`0`,`1`,`2`,`3`,`6`,`12`)*average_bump),
           bump={
               print("abc");
               print(abc);
               abc[[1]]},
           worsen=abc[[2]],
           improve=abc[[3]]) %>%
    ungroup() %>%   
    select(-abc) %>%
    select(id, bump, cbump) %>%
    inner_join(demographics, by="id");

dataset <- vectors_proj %>%
    select(bump,
           cbump,
           education, 
           ethnicity, 
           hispanic, 
           employment_status, 
           exercise, 
           married_or_living_as_marri, 
           age, 
           gender, 
           weight) %>%
    mutate(education=as.numeric(education),
           ethnicity=factor(ethnicity),
           hispanic=factor(hispanic),
           employment_status=as.numeric(employment_status),
           exercise=as.numeric(exercise),
           married_or_living_as_marri = factor(married_or_living_as_marri),
           age = as.numeric(age),
           gender = factor(gender),
           weight = as.numeric(weight));
f <- bump ~ education +
    ethnicity +
    hispanic +
    employment_status +
    exercise +
    married_or_living_as_marri +
    age +
    gender +
    weight;
# Get the number of CPU cores using a shell command
n_cores <- as.numeric(system("nproc", intern = TRUE))

# Define the formula
f <- bump ~ education +
    ethnicity +
    hispanic +
    employment_status +
    exercise +
    married_or_living_as_marri +
    age +
    gender +
    weight;

# Fit the model with 5-fold cross-validation
model <- gbm(f, distribution="gaussian", data=dataset, cv.folds=5, n.cores=n_cores)
dataset <- dataset %>% mutate(bump.pred=predict(model, newdata=dataset, n.trees=40));
ggplot(dataset, aes(bump, bump.pred)) + geom_point() + xlim(-1,1) + ylim(-1,1);
