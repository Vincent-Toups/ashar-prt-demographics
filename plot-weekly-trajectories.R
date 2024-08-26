library(tidyverse);

# Load data
outcomes_long <- read_csv("private_data/final_12mo_outcomes_long.csv");


week_map <- block({
    redcap_event_name <- c("baseline",
                        "treatmentweekly1_arm_1",
                        "treatmentweekly2_arm_1",
                        "treatmentweekly3_arm_1",
                        "treatmentweekly4_arm_1",
                        "treatmentweekly5_arm_1",
                        "treatmentweekly6_arm_1",
                        "treatmentweekly7_arm_1",
                        "treatmentweekly8_arm_1",
                        "t2_arm_1");
    week <- seq(from=0, length.out=length(redcap_event_name));
    tibble(redcap_event_name=redcap_event_name, week=week);                         
});

outcomes_week <- outcomes_long %>% inner_join(week_map, by="redcap_event_name");

plot_metric <- function(tbl, metric, save_to){
    p <- ggplot(tbl, aes(week,{{metric}})) +
        geom_line(aes(color=factor(id))) +
        scale_colour_discrete(guide = "none");
    ggsave(save_to, plot=p);
    p
}
plot_metric(outcomes_week,
            bpi_intensity,
            "figures/weekly_bpi_intensity.png")

plot_metric(outcomes_week,
            tsk11,
            "figures/tsk11.png");

plot_metric(outcomes_week,
            promise_anger,
            "figures/promise_anger.png");




## # SET UP. USED IN MULTIPLE CELLS BELOW
## wh1 <- outcomes_wide_prt$group == 1
## wh2 <- outcomes_wide_prt$group == 2
## wh3 <- outcomes_wide_prt$group == 3

## timepoints <- c("_baseline",
##                 "_treatmentweekly1_arm_1",
##                 "_treatmentweekly2_arm_1",
##                 "_treatmentweekly3_arm_1",
##                 "_treatmentweekly4_arm_1",
##                 "_treatmentweekly5_arm_1",
##                 "_treatmentweekly6_arm_1",
##                 "_treatmentweekly7_arm_1",
##                 "_treatmentweekly8_arm_1",
##                 "_t2_arm_1");

## xvals <- 1:length(timepoints)

## xlab <- gsub("_", " ", timepoints)
## xlab <- gsub("treatmentweekly", "week", xlab)
## xlab <- gsub("baseline", "Baseline", xlab)
## xlab <- gsub("t2", "Post-tx", xlab)

## # plot trajectories, individual subject view
## myoutcome <- "tsk11"
## cols <- paste0(myoutcome, timepoints)
## datmat1 <- outcomes_wide_prt[wh3, cols]
## datmat2 <- outcomes_wide_prt[wh1, cols]

## datmat1 <- as.data.frame(datmat1)
## datmat2 <- as.data.frame(datmat2)

## # plot single subject, multiple variables
## for (i in which(wh1)) {
  
##   myoutcome <- "bpi_intensity"
##   cols <- paste0(myoutcome, timepoints)
##   datmat <- as.data.frame(outcomes_wide_prt[i, cols])
##   datmat <- tidyr::gather(datmat)
##   datmat$Outcome <- "Pain"
  
##   myoutcome <- "tsk11"
##   cols <- paste0(myoutcome, timepoints)
##   tmp <- as.data.frame(outcomes_wide_prt[i, cols]) * 2
##   tmp <- tidyr::gather(tmp)
##   tmp$Outcome <- "TSK"
##   datmat <- rbind(datmat, tmp)
  
##   myoutcome <- "promis_anger"
##   cols <- paste0(myoutcome, timepoints)
##   tmp <- as.data.frame(outcomes_wide_prt[i, cols]) * 2
##   tmp <- tidyr::gather(tmp)
##   tmp$Outcome <- "Anger"
##   datmat <- rbind(datmat, tmp)
  
##   myoutcome <- "promis_dep"
##   cols <- paste0(myoutcome, timepoints)
##   tmp <- as.data.frame(outcomes_wide_prt[i, cols]) * 2
##   tmp <- tidyr::gather(tmp)
##   tmp$Outcome <- "Depression"
##   datmat <- rbind(datmat, tmp)
  
##   datmat$Timepoint <- factor(datmat$key, levels = paste0(myoutcome, timepoints), labels = xlab)
  
##   ggplot(datmat, aes(x = Timepoint, y = value, color = Outcome, group = Outcome)) +
##     geom_line() +
##     geom_point() +
##     theme(axis.text.x = element_text(angle = 30, hjust = 1)) +
##     labs(title = paste("Subj", i), x = "", y = "") +
##       scale_color_manual(values = c("Pain"="black", "TSK"="green", "Anger"="red", "Depression"="blue")) +
##       guides(color = guide_legend(title = NULL)) +
##       theme_minimal()

##     ggsave(paste0("Subj_", i, ".png"), width = 10, height = 6, dpi = 300)

## }
