
set_theme <- function(
    
    theme = theme_classic(),
    size = 16, 
    title_hjust = 0.5,
    y_title_size = size,
    x_title_size = size,
    y_title_margin = NULL,
    x_title_margin = NULL,
    y_text_size = size,
    x_text_size = size,
    y_text_color = "black",
    x_text_color = "black",
    y_title_color = "black", 
    x_title_color = "black",
    legend_text_size = size,
    legend_position = "none",
    legend_key_fill = NA,
    legend_key_color = NA,
    plot_title_position = NULL,
    plot_margin = margin(25, 25, 10, 25),
    axis_title_y_blank = FALSE, # to fully left-align
    aspect_ratio = NULL,
    plot_caption_position = "plot",
    axis_line_x  = element_blank(),
    axis_line_y = element_blank(),
    axis_text_x = element_markdown(size = x_text_size, color = y_text_color, family="LM Roman 10"),
    axis_text_y = element_markdown(size = y_text_size, color = y_text_color, family="LM Roman 10"),
    legend_box_background = element_rect(fill = "white", color = "black")
    
) {
  
  # Dependencies
  require(ggplot2)
  require(stringr)
  require(ggtext)
  
  # Size
  size_ <- str_c("size = ", size) # this argument always included
  
  if (is.na(y_title_size)) {
    y_title <- "element_blank()"
  } else {
    
    # y-title margin
    if (!is.null(y_title_margin)) y_title_margin_ <- str_c("margin = margin(", y_title_margin, ")")
    else y_title_margin_ <- ""
    
    
    # y-title color
    if (!is.null(y_title_color)) y_title_color_ <- str_c("color = '", y_title_color, "'")
    else y_title_color_ <- ""
    
    # create y_title
    y_title <- str_c("element_text(", size_, ",", y_title_margin_, ",", y_title_color_, ")")
    
  }
  if (is.na(x_title_size)) {
    x_title <- "element_blank()"
  }
  else {
    # x-title margin
    if (!is.null(x_title_margin)) x_title_margin_ <- str_c("margin = margin(", x_title_margin, ")")
    else x_title_margin_ <- ""
    
    # x-title color
    if (!is.null(x_title_color)) x_title_color_ <- str_c("color = '", x_title_color, "'")
    else x_title_color_ <- ""
    
    # create x_title
    x_title <- str_c("element_text(", size_, ",", x_title_margin_, ",", x_title_color_, ")")
  }
  
  if (axis_title_y_blank) {
    y_title <- "element_blank()" # overwrite what it was written as above
  }
  
  # Legend key
  if (is.na(legend_key_fill) & is.na(legend_key_color)) {
    legend_key <- "element_blank()"
  } else {
    if (is.na(legend_key_fill) & !(is.na(legend_key_color))) {
      legend_key <- str_c("element_rect(", 
                          "fill = NA", ",",
                          "color = '", legend_key_color, "'", ", ",
                          ")"
      )      
    } else if (!(is.na(legend_key_fill)) & is.na(legend_key_color)) {
      legend_key <- str_c("element_rect(", 
                          "fill = '", legend_key_fill, "'", ", ",
                          "color = NA",
                          ")"
      )      
    } else { # neither missing
      legend_key <- str_c("element_rect(", 
                          "fill = '", legend_key_fill, "'", ", ",
                          "color = '", legend_key_color, "'",
                          ")"
      )
    }
  }
  
  theme + theme(
    plot.title =  element_text(hjust = -0.05, size = size, color = y_text_color, family="LM Roman 10"),
    axis.title.y = eval(parse(text = y_title)),
    axis.title.x = eval(parse(text = x_title)),
    axis.text.y = axis_text_y,
    axis.text.x = axis_text_x,
    axis.line.x = axis_line_x , # manual axes
    axis.line.y = axis_line_y,
    legend.key = eval(parse(text = legend_key)),
    legend.text = element_text(size = legend_text_size, family="LM Roman 10"),
    legend.title = element_text(size = legend_text_size, family="LM Roman 10"),
    aspect.ratio = aspect_ratio,
    plot.margin = plot_margin,
    legend.position = legend_position,
    plot.caption.position = plot_caption_position,
    plot.caption = element_text(size = 12, color = "gray50", family="LM Roman 10"),
    text         = element_text(family="LM Roman 10", color = "black"),
    axis.ticks.length = unit(.25, "cm"),
    legend.box.background = legend_box_background
  ) 
  
} 
