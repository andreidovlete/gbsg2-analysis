# GBSG2 Breast Cancer Survival Analysis

This project performs an exploratory and survival analysis using the `GBSG2` dataset from the `TH.data` package. The goal is to explore receptor data, assess correlations, and model survival outcomes using the Kaplan-Meier estimator. Basic prediction is performed for new patients based on lymph node groupings.

## Problem-Solving Approach

1. **Descriptive Statistics**: Calculate summary statistics for progesterone and estrogen receptors.
2. **Statistical Testing**:
   - Shapiro-Wilk tests for normality
   - Wilcoxon signed-rank test for comparing paired hormone receptor levels
3. **Visualization**:
   - Correlation heatmap
   - Histogram of age distribution
   - Contingency heatmap (hormonal therapy vs censoring)
4. **Survival Analysis**:
   - Kaplan-Meier modeling stratified by number of positive lymph nodes
   - Basic prediction of survival probability at a fixed time point (1000 days) for new patients

## Libraries Used

```r
library(TH.data)
library(tidyverse)
library(ggplot2)
library(survival)
library(survminer)
library(reshape2)
