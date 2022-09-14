library(tidyverse);
library(reticulate);
use_python("/usr/bin/python3");

keras <- import("keras");
backend <- import("keras.backend");
kmodels <- import("keras.models");

py_run_string("import keras;
from keras import backend, models;
enc = models.load_model('models/reduced-demographics-enc');
vae = models.load_model('models/reduced-demographics-ae')")
data <- read_csv("derived_data/reduced-demographics-one-hot.csv");

enc <- py$enc;
vae <- py$vae;

proj <- enc$predict(data %>% dplyr::select(married, age, weight, ethnicity_white, ethnicity_other,
                                    ethnicity_black, ethnicity_hispanic, gender_female,
                                    gender_male)) %>%
    as.data.frame() %>%
    transmute(AE1=V1, AE2=V2) %>%
    as_tibble();

proj <- cbind(proj, data);

proj_plot <- ggplot(proj, aes(AE1, AE2)) + geom_point(aes(color=factor(ethnicity_white)));
ggsave("figures/reduced_demographic_projection.png", plot=proj_plot);

pred <- vae$predict(data %>% select(married, age, weight, ethnicity_white, ethnicity_other,
                                    ethnicity_black, ethnicity_hispanic, gender_female,
                                    gender_male)) %>% as.data.frame() %>%
    transmute(married=V1, age=V2, weight=V3, ethnicity_white=V4, ethnicity_other=V5,
              ethnicity_black=V6, ethnicity_hispanic=V7, gender_female=V8,
              gender_male=V9) %>%
    as_tibble();

# How to save a non-ggplot figure.
png("figures/reduced-demo-married-roc.png");
verification::roc.plot(data$married, pred$married);
dev.off();

png("figures/reduced-demo-ethnicity_white-roc.png");
verification::roc.plot(data$ethnicity_white, pred$ethnicity_white);
dev.off();

png("figures/reduced-demo-gender_female-roc.png");
verification::roc.plot(data$gender_female, pred$gender_female);
dev.off();


