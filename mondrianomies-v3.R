####################################################################
library(gsubfn)
library(tidyverse)

# Number of symbols in rule
s <- sample(15:26, 1) 
# Extract s symbols from c("F", "+", "-") randomly
v1 <- sample(c("F", "+", "-"), size = s, replace = TRUE, prob = c(10,12,12))
# Add 3 pairs of brackets
v2 <- sample("[]", 3, replace = TRUE) %>% str_extract_all("\\d*\\+|\\d*\\-|F|L|R|\\[|\\]|\\|") %>% unlist
# Where to insert brackets
v3 <- sample(1:(s+1), size = length(v2)) %>% sort
# Insert them correctly
for(i in 1:length(v3)){
  c(v1[1:(v3[i] + i - 1)], v2[i], v1[(v3[i] + i - 1):length(v1)]) -> v1
}

# All ictures start with the same axiom
axiom <- "F-F-F-F"
# Rule to substitute F, as generated previously
rules <- list("F"=paste(v1, collapse=""))
# Turning angle
angle <- 90
# Haw many times to apply the rule
depth <- sample(3:4,1)
# Longitude (factor) of the segments
ds <- jitter(1)
# Substitute axiom depth times
for (i in 1:depth) axiom <- gsubfn(".", rules, axiom)
# Actions that will gneerate the drawing  
actions <- str_extract_all(axiom, "\\d*\\+|\\d*\\-|F|L|G|R|\\[|\\]|\\|") %>% unlist
  
# These vars store the current position, angle and longitude factor of the point
x_current <- 0
y_current <- 0
a_current <- 0
d_current <- 0

# To store point position, angle and longitude
status <- tibble(x = x_current, 
                 y = y_current, 
                 alfa = a_current,
                 depth = d_current)
# To store segments  
lines <- data.frame(x = numeric(), 
                    y = numeric(), 
                    xend = numeric(), 
                    yend = numeric())

# This loop reads actions and generates the drawing depending on the concrete action
#   F -> draw forward
#   + -> turn right
#   - -> turn left
#   [ -> save the current status of point
#   ] -> restore the last current status of point and remove from stack
for (action in actions) 
{
  if (action=="F") {
    lines <- lines %>% add_row(x = x_current,
                               y = y_current,
                               xend = x_current + (ds^d_current) * cos(a_current * pi / 180),
                               yend = y_current + (ds^d_current) * sin(a_current * pi / 180)) 
    x_current <- x_current + (ds^d_current) * cos(a_current * pi / 180)
    y_current <- y_current + (ds^d_current) * sin(a_current * pi / 180)
    d_current <- d_current + 1
  }
  if (action=="+") {
    a_current <- a_current - angle
  }
  if (action=="-") {
    a_current <- a_current + angle
  }
  if (action=="[") { 
    status <- status %>% add_row(x = x_current, 
                                 y = y_current, 
                                 alfa = a_current,
                                 depth = d_current)
  }
  if (action=="]") {
    x_current <- tail(status, 1) %>% pull(x)
    y_current <- tail(status, 1) %>% pull(y)
    a_current <- tail(status, 1) %>% pull(alfa)
    d_current <- tail(status, 1) %>% pull(depth)
    status <- head(status, -1)
  }
}

  lines %>%
    mutate(x = round(x, 1),
           y = round(y, 1),
           xend = round(xend, 1),
           yend = round(yend, 1)) %>%
    distinct(x, y, xend, yend) -> lines
  
  select(lines, x3 = x, y3 =y) %>%
    bind_rows(select(lines, x3 = xend, y3 =yend)) %>%
    distinct(x3, y3) -> points
  
# Let's find squares to fill inside the drawing
# Since this operation maybe hard to compute, I divide points into 
# 10 pieces to process them separately
n <- 10
  
split(points, rep(1:ceiling(nrow(points)/n), 
                  each = n, 
                  length.out = nrow(points))) -> points_divided
  
# Squares1: add X3, y3 to current segments and filter to find 
# right angles
  lapply(points_divided, function(sub) {
    sub %>% 
      crossing(lines) %>%
      filter(x == x3 | y == y3 | xend == x3 | yend == y3) %>%
      filter(x != x3 | y != y3 , xend != x3 | yend != y3) %>%
      mutate(id = row_number())
  }) %>% bind_rows() -> squares1
  
# Squares2:  keep those squares where some of new sides exist in lines
bind_rows(
    squares1 %>%
      inner_join(lines, c("x" = "x", 
                          "y" = "y", 
                          "x3" = "xend", 
                          "y3" = "yend")),
    squares1 %>%
      inner_join(lines, c("xend" = "x", 
                          "yend" = "y", 
                          "x3" = "xend", 
                          "y3" = "yend")),
    squares1 %>%
      inner_join(lines, c("x3" = "x", 
                          "y3" = "y", 
                          "x" = "xend", 
                          "y" = "yend")),
    squares1 %>%
      inner_join(lines, c("x3" = "x", 
                          "y3" = "y", 
                          "xend" = "xend", 
                          "yend" = "yend"))) %>%
    distinct(x, y, xend, yend, x3, y3, id) -> squares2
  
# Remove those whose sides form a straight line
squares2 %>% 
    anti_join(squares2 %>% filter(x == xend, xend == x3),
              by = c("x", "y", "xend", "yend", "x3", "y3", "id")) -> squares2
  
squares2 %>% 
    anti_join(squares2 %>% filter(y == yend, yend == y3),
              by = c("x", "y", "xend", "yend", "x3", "y3", "id")) -> squares2
  
# We leave squares2 prepared for geom_rect
squares2 %>%
    mutate(xmax = pmax(x, xend, x3),
           xmin = pmin(x, xend, x3),
           ymax = pmax(y, yend, y3),
           ymin = pmin(y, yend, y3)) %>%
    mutate(A = (xmax - xmin) * (ymax - ymin) / 2) -> squares
  
# Piet mondrian's palette
# https://www.color-hex.com/color-palette/27086
colors <- c("#f9f9f9","#30303a","#ff0101","#fff001", "#0101fd")

# To remove very small squares I calculate quantiles form its area
qnts <- quantile(squares$A, 
                   probs = seq(0, 1, 0.05), 
                   na.rm = FALSE,
                   names = TRUE, 
                   type = 7)

# Here comes the magic of ggplot
ggplot() +
    geom_rect(aes(xmax = xmax,
                  xmin = xmin,
                  ymax = ymax,
                  ymin = ymin,
                  fill = id %% length(colors) %>% jitter(amount=.025)),
              data = squares %>% filter(A >= qnts[1]), # remove small squares
              lwd = 2,
              color = "white") +
    geom_segment(aes(x = x, y = y, xend = xend, yend = yend),
                 data = lines,
                 lwd = .65,
                 lineend = "square",
                 color = "#000002") +
    scale_fill_gradientn(colors = colors) +
    theme_void() +
    theme(legend.position = "none") +
    coord_equal() -> plot

plot
  
# Calculate dimensions of the picture for ggsave
width <- max(points$x3) - min(points$x3)
height <- max(points$y3) - min(points$y3)
  
whmax <- 8
if (width >= height) {
  w <- whmax
  h <- whmax * height / width 
} else {
  h <- whmax
    w <- whmax * width / height
}
  
# Save the drawing with a random name
name <- paste(sample(letters,6), collapse = "")
ggsave(paste0("~/Downloads/",name,".png"), plot, width = w, height = h)



  

