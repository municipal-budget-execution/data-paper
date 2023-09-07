plot_dynamic_did <- function(clfe, semester = FALSE, quarter = FALSE) {
  
  
  variable  = as.character(clfe[["fml_all"]][["linear"]][[2]])
  treatment = as.character(reg_results[[1]][["fml"]][[3]][[3]])
  list = list()
  list[[1]] = variable
  list[[2]] = treatment
  list = do.call(rbind, list)
  data = data_reg
  colnames(data)[1] = "var"
  colnames(data)[2] = "treatment"
  
  mean_late  = format(mean(data[treatment == TRUE,]$var, na.rm = TRUE), digits = 2, big.mark = ",", format = "f")
  mean_early = format(mean(data[treatment == FALSE,]$var, na.rm = TRUE), digits = 2, big.mark = ",", format = "f")
  
  if (semester == FALSE & quarter == FALSE) {
    
    results <- confint(clfe)
    colnames(results) <- c("ci_low", "ci_up")
    results$coefficients <- clfe$coefficients
    results <- results %>% add_row(
      ci_low = 0, 
      ci_up = 0,
      coefficients = 0,
      .after = 3
    )
    results$year <- seq(2016, 2021, by = 1)
    
    
    min = min(unique(results[,1]))
    min = data.table::fcase(
      min < 5 & min > -5, plyr::round_any(min, accuracy = 0.05, f = floor),
      min > 5 & min < -5, floor(min)
    )
    
    max = max(unique(results[,2]))
    max = data.table::fcase(
      max < 5 & max > -5, plyr::round_any(max, accuracy = 0.05, f = ceiling),
      max > 5 & max < -5, ceiling(min)
    )
    
    plot <- ggplot()  +
      
      geom_errorbar(
        data = results,
        aes(
          x    = year, 
          y    = coefficients,
          ymin = ci_low,
          ymax = ci_up,
          width = 0.05,
          group = 1
        ),
        colour = "red"
      ) + 
      
      geom_point(
        data = results,
        aes(
          x = year       ,
          y = coefficients),
        size = 2) +
      
      scale_x_continuous(breaks = seq(2016, 2021, by = 1),
                         label = c("2016", "2017", "2018", "2019", "2020", "2021"),
                         limits = c(2015, 2022)) +
      scale_y_continuous(limits = c(min, max)) +
      set_theme( 
        axis_line_x = element_line(),
        axis_line_y = element_line()
      ) +
      geom_hline(yintercept = 0) +
      geom_vline(xintercept = 2019, size = 1, color = "red", alpha = 1, linetype = "dotted") +
      geom_hline(yintercept = as.numeric(mean_late ), size = 1, color = "black", alpha = 0.8, linetype = "dotted") +
      geom_hline(yintercept = as.numeric(mean_early), size = 1, color = "black", alpha = 0.8, linetype = "dotted") +
      
      xlab("") +
      ylab("") +
      labs(caption = "Buyer and Semester Fixed Effects. Standard errors are clustered at the buyer level.") 
    
    return(plot)
    
  } else if (semester == TRUE & quarter == FALSE) {
      
    results <- confint(clfe)
    colnames(results) <- c("ci_low", "ci_up")
    results$coefficients <- clfe$coefficients
    results <- results %>% add_row(
      ci_low = 0, 
      ci_up = 0,
      coefficients = 0,
      .after = 7
    )
    results$year         <- seq(2016, 2021.5, by = 0.5)
    
    min = min(unique(results[,1]))
    min = data.table::fcase(
      min < 5 & min > -5, plyr::round_any(min, accuracy = 0.05, f = floor),
      min > 5 & min < -5, floor(min)
    )
    
    max = max(unique(results[,2]))
    max = data.table::fcase(
      max < 5 & max > -5, plyr::round_any(max, accuracy = 0.05, f = ceiling),
      max > 5 & max < -5, ceiling(min)
    )
    
    plot <- ggplot()  +
      
      geom_errorbar(
        data = results,
        aes(
          x    = year, 
          y    = coefficients,
          ymin = ci_low,
          ymax = ci_up,
          width = 0.05,
          group = 1
        ),
        colour = "red"
      ) + 
      
      geom_point(
        data = results,
        aes(
          x = year       ,
          y = coefficients),
        size = 2) +
      
      scale_x_continuous(breaks = seq(2016, 2021.5, by = 0.5),
                         label = c("S1 2016", "S2 2016",
                                   "S1 2017", "S2 2017",
                                   "S1 2018", "S2 2018",
                                   "S1 2019", "S2 2019",
                                   "S1 2020", "S2 2020",
                                   "S1 2021", "S2 2021"),
                         limits = c(2015.5, 2021.5)) +
      scale_y_continuous(limits = c(min, max)) +
      set_theme( 
        axis_line_x = element_line(),
        axis_line_y = element_line()
      ) +
      geom_hline(yintercept = 0) +
      geom_vline(xintercept = 2019.5, size = 1, color = "red", alpha = 1, linetype = "dotted") +
      xlab("") +
      ylab("")  +
      labs(caption = "Buyer and Semester Fixed Effects. Standard errors are clustered at the buyer level.")
    
    return(plot)
      
      
  } else if (semester == FALSE & quarter == TRUE) {
    
    results <- confint(clfe)
    colnames(results) <- c("ci_low", "ci_up")
    results$coefficients <- clfe$coefficients
    results <- results %>% add_row(
      ci_low = 0, 
      ci_up = 0,
      coefficients = 0,
      .after = 15
    )
    results$year         <- seq(2016.25, 2022, by = 0.25)
    
    min = min(unique(results[,1]))
    min = data.table::fcase(
      min < 5 & min > -5, plyr::round_any(min, accuracy = 0.05, f = floor),
      min > 5 & min < -5, floor(min)
    )
    
    max = max(unique(results[,2]))
    max = data.table::fcase(
      max < 5 & max > -5, plyr::round_any(max, accuracy = 0.05, f = ceiling),
      max > 5 & max < -5, ceiling(min)
    )
    
    plot <- ggplot()  +
      
      geom_errorbar(
        data = results,
        aes(
          x    = year, 
          y    = coefficients,
          ymin = ci_low,
          ymax = ci_up,
          width = 0.05,
          group = 1
        ),
        colour = "red"
      ) + 
      
      geom_point(
        data = results,
        aes(
          x = year       ,
          y = coefficients),
        size = 2) +
      
      scale_x_continuous(breaks = seq(2016.25, 2022, by = 0.25),
                         label = c("Q1 2016", "Q2 2016",
                                   "Q3 2016", "Q4 2016",
                                   "Q1 2017", "Q2 2017",
                                   "Q3 2017", "Q4 2017",
                                   "Q1 2018", "Q2 2018",
                                   "Q3 2018", "Q4 2018",
                                   "Q1 2019", "Q2 2019",
                                   "Q3 2019", "Q4 2019",
                                   "Q1 2020", "Q2 2020",
                                   "Q3 2020", "Q4 2020",
                                   "Q1 2021", "Q2 2021",
                                   "Q3 2021", "Q4 2021"),
                         limits = c(2015.75, 2022.5)) +
      scale_y_continuous(limits = c(min, max)) +
      set_theme( 
        axis_line_x = element_line(),
        axis_line_y = element_line(),
        axis_text_x = element_markdown(angle = 45, vjust = 1, hjust = 1, size = 16, color = "black", family="LM Roman 10")
      ) +
      geom_hline(yintercept = 0) +
      geom_vline(xintercept = 2020, size = 1, color = "red", alpha = 1, linetype = "dotted") +
      xlab("") +
      ylab("")  +
      labs(caption = "Buyer and Semester Fixed Effects. Standard errors are clustered at the buyer level.")
    
    return(plot)
    
    
  }
}


