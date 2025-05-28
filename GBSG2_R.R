# Load required libraries
library(TH.data)        # Provides the GBSG2 dataset (German Breast Cancer Study Group)
library(tidyverse)      # Collection of R packages for data manipulation and visualization
library(ggplot2)        # Visualization package
library(survival)       # For survival analysis (Kaplan-Meier, Cox, etc.)
library(survminer)      # Enhanced visualizations for survival models
library(reshape2)       # Data reshaping, used here for melting the correlation matrix

# Load and convert the GBSG2 dataset into a standard data frame
data("GBSG2")
gbsg <- as.data.frame(GBSG2)

# Descriptive Statistics

# Calculate summary statistics for progesterone (progrec) and estrogen (estrec) receptors
summary_receptors <- gbsg %>% 
  summarise(
    Mean_Progrec = mean(progrec, na.rm = TRUE),
    Median_Progrec = median(progrec, na.rm = TRUE),
    StdDev_Progrec = sd(progrec, na.rm = TRUE),
    Min_Progrec = min(progrec, na.rm = TRUE),
    Max_Progrec = max(progrec, na.rm = TRUE),
    IQR_Progrec = IQR(progrec, na.rm = TRUE),
    
    Mean_Estrec = mean(estrec, na.rm = TRUE),
    Median_Estrec = median(estrec, na.rm = TRUE),
    StdDev_Estrec = sd(estrec, na.rm = TRUE),
    Min_Estrec = min(estrec, na.rm = TRUE),
    Max_Estrec = max(estrec, na.rm = TRUE),
    IQR_Estrec = IQR(estrec, na.rm = TRUE)
  )

# Normality Tests

# Shapiro-Wilk test checks if the data is normally distributed
shapiro_progrec <- shapiro.test(gbsg$progrec)
shapiro_estrec <- shapiro.test(gbsg$estrec)

# ------------------------
# Statistical Comparison
# ------------------------

# Wilcoxon signed-rank test compares paired samples (non-parametric)
# Here used to compare progrec vs. estrec levels
wilcox_test <- wilcox.test(gbsg$progrec, gbsg$estrec, paired = TRUE)

# Correlation Heatmap


# Compute correlation matrix among selected numeric variables
cor_matrix <- cor(gbsg[, c("age", "tsize", "pnodes", "progrec", "estrec")], use = "complete.obs")

# Melt matrix for ggplot compatibility
cor_matrix_melt <- melt(cor_matrix)
colnames(cor_matrix_melt) <- c("var1", "var2", "value")

# Plot heatmap of correlation matrix
ggplot(cor_matrix_melt, aes(var1, var2, fill = value)) +  
  geom_tile() +
  scale_fill_gradient2(midpoint = 0, low = "blue", mid = "white", high = "red", limits = c(-1, 1)) +
  labs(title = "Correlation Matrix of Numerical Variables",
       x = "Variable", y = "Variable", fill = "Correlation") +
  theme_minimal(base_size = 14)

# Histogram of Patient Ages

# Plot histogram with density overlay and text labels
ggplot(gbsg, aes(x = age)) +
  geom_histogram(binwidth = 5, fill = "lightblue", color = "darkblue", alpha = 0.7) +
  geom_density(aes(y = ..count.. * 5), color = "red", size = 1.2, linetype = "dashed") +
  stat_bin(binwidth = 5, geom = "text", aes(label = ..count..), vjust = -0.5, size = 4, color = "darkblue") +
  labs(title = "Age Distribution of Patients",
       x = "Age (Years)", y = "Count") +
  theme_minimal(base_size = 14)


# Contingency Table: Hormonal Treatment vs. Censoring

# Create a contingency table between hormonal therapy (horTh) and censoring (cens)
contingency_table <- table(gbsg$horTh, gbsg$cens)
contingency_table_df <- as.data.frame(contingency_table)

# Print contingency table to console
print(contingency_table)

# Visualize contingency table using ggplot2 tile plot
ggplot(contingency_table_df, aes(Var1, Var2, fill = Freq)) +
  geom_tile() +
  geom_text(aes(label = Freq), color = "white", size = 5) +
  labs(title = "Contingency Table: Hormonal Treatment vs. Censoring",
       x = "Hormonal Treatment", y = "Censoring", fill = "Count") +
  theme_minimal()

# Kaplan-Meier Survival Model

# Create categorical groups for number of positive lymph nodes
gbsg$pnodes_group <- cut(gbsg$pnodes,
                         breaks = c(-1, 3, 9, Inf),
                         labels = c("0–3 Lymph Nodes", "4–9 Lymph Nodes", "10+ Lymph Nodes"))

# Fit Kaplan-Meier survival model stratified by lymph node group
km_fit_grouped <- survfit(Surv(time, cens) ~ pnodes_group, data = gbsg)

# Plot Kaplan-Meier survival curve with confidence intervals
ggsurvplot(km_fit_grouped, data = gbsg,
           title = "Kaplan-Meier Survival Curve by Affected Lymph Nodes",
           xlab = "Time (days)", ylab = "Survival Probability",
           conf.int = TRUE,
           risk.table = FALSE,
           palette = c("forestgreen", "darkorange", "firebrick"),
           legend.title = "Lymph Node Groups",
           legend.labs = levels(gbsg$pnodes_group),
           ggtheme = theme_minimal())


# Survival Predictions for New Patients (Fixed)

# Choose a specific time point (e.g., 1000 days) to extract survival probability
target_time <- 1000

# Extract survival probabilities at that time from the Kaplan-Meier model
surv_summary <- summary(km_fit_grouped, times = target_time)

# Create a survival_df with group labels and survival probabilities at day 1000
survival_df <- data.frame(
  pnodes_group = surv_summary$strata,
  survival_prob = surv_summary$surv
)

# Ensure group labels match the factor levels used in 'gbsg$pnodes_group'
survival_df$pnodes_group <- gsub("^pnodes_group=", "", survival_df$pnodes_group)

# Define new patients
new_patients <- data.frame(
  age = c(55, 65),
  tsize = c(25, 35),
  pnodes = c(6, 12),
  progrec = c(60, 90),
  estrec = c(40, 70)
)

# Assign each patient to a lymph node group
new_patients$pnodes_group <- cut(
  new_patients$pnodes,
  breaks = c(-1, 3, 9, Inf),
  labels = c("0–3 Lymph Nodes", "4–9 Lymph Nodes", "10+ Lymph Nodes")
)

# Merge new_patients with survival_df to get predicted survival
new_patients <- merge(new_patients, survival_df, by = "pnodes_group", all.x = TRUE)

# Rename for clarity
colnames(new_patients)[colnames(new_patients) == "survival_prob"] <- "Predicted_Survival_Prob_Day1000"

# Print predictions
print(new_patients)
