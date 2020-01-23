# Open Libraries - don't forget to install the packages in your R/R-studio before running your code
library(plyr)
library(ggplot2)
library(scales)
# Open files and then subset them
flCensus <- read.csv("C:/Users/hooverjh/Desktop/psam_h12.csv")
flGville <- subset(flCensus, PUMA==00101)
# Censor the file for better visualizations
flCensus4 <- subset(flCensus, HINCP<=500000)
# Histogram data visualizations in a facet wrap
p <- ggplot(flCensus4, aes(HINCP/10000)) + geom_histogram(binwidth=2,color="black",fill="white") + facet_wrap(~VEH)
p
# Boxplot data visualizations in a 
p <- ggplot(flCensus4, aes(x=VEH, y=HINCP/10000, group=VEH)) + 
  geom_boxplot(varwidth = TRUE)
p