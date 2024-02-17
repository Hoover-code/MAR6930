# Starting a line with a # indicates that the line is a comment and for the program to ignore it
# It is good coding hygene to comment your code so others can understand what the code is doing
# This script illustrates how to scrape the same data from the web the way we did in Excel.
# The WFB site is: https://www.worldometers.info/world-population/population-by-country/
# The code is a modification from this link:
# http://bradleyboehmke.github.io/2015/12/scraping-html-tables.html

# First, we will load the Packages (Library) necessary to scrape the website
# This packages need to be "Installed" in R first

library(rvest)
library(openxlsx)

# read the webpage table into memory
webpage <- read_html("https://www.worldometers.info/world-population/population-by-country/")
tbls <- html_nodes(webpage,"table")
head(tbls)
tbls_ls <- webpage %>%
  html_nodes("table") %>%
  .[1] %>%
  html_table(fill = TRUE)
population <- data.frame(tbls_ls)

write.xlsx(population, "population_table_r.xlsx")
