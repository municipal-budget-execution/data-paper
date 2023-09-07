# Rut checkin

rut_check <- function(data, variable, without_dots = FALSE) {
  
  variable <- enquo(variable)
  
  if(without_dots == TRUE) {
    
    # We do a first cleaning
    data <- data %>% 
      dplyr::mutate(
        var = substr(!!variable, 0, nchar(!!variable) - 1) # we remove the digit check
      ) %>% 
      dplyr::mutate(
        var = str_remove_all(var, pattern = SPACE) # remove space
      ) 
    
  } else {
    
    # We code one and two digits 
    one_two_dgt <- or(DGT, DGT %R% DGT)
    three_dgt   <- DGT %R% DGT %R% DGT
    
    # This should be the pattern
    pattern_rut <- one_two_dgt %R%  "." %R% three_dgt %R% "." %R% three_dgt %R% "-"
    
    # We do a first cleaning
    data <- data %>% 
      dplyr::mutate(
        var = substr(!!variable, 0, nchar(!!variable) - 1) # we remove the digit check
      ) %>% 
      dplyr::mutate(
        var = str_remove_all(var, pattern = SPACE) # remove space
      ) %>% 
      dplyr::mutate(
        var = ifelse(str_detect(var, pattern = pattern_rut), var, NA) # remove all variables that do not match the pattern
      ) 
    
  }
  
  # Now, we can recompute the check digit 
  data <- data %>% 
    mutate(
      check_digit = gsub('[^[:alnum:] ]','', var) # we keep only the numbers
    ) %>% 
    # we seperate each digit in columns 
    separate(check_digit, into = c('digit_9', 'digit_8', 'digit_7', 'digit_6', 'digit_5', 'digit_4', 'digit_3', 'digit_2', 'digit_1'), sep = seq(1, 9, by = 1), remove = FALSE) %>% 
    # replace missing digit with a 0 
    mutate(across(starts_with("digit"), ~ as.numeric(.x))) %>% 
    mutate(check_digit = as.numeric(check_digit)) %>% 
    # we compute the formula
    mutate(
      digit_1     = case_when(
        !is.na(digit_1) ~ digit_1 * 2, 
        is.na(digit_1) ~ digit_1
      ),
      digit_2     = case_when(
        !is.na(digit_1)                   ~ digit_1 * 3, 
        is.na(digit_1) &  is.na(digit_2) ~     digit_2,
        is.na(digit_1) & !is.na(digit_2) ~ digit_2 * 2
      ),
      digit_3     = case_when(
        !is.na(digit_1)                                     ~ digit_3 * 4, 
        is.na(digit_1) &  is.na(digit_2) &  is.na(digit_3) ~     digit_3,
        is.na(digit_1) &  is.na(digit_2) & !is.na(digit_3) ~ digit_3 * 2,
        is.na(digit_1) & !is.na(digit_2)                   ~ digit_3 * 3
      ),
      digit_4     = case_when(
        !is.na(digit_1)                                     ~ digit_4 * 5, 
        is.na(digit_1) &  is.na(digit_2) &  is.na(digit_3) ~ digit_4 * 2,
        is.na(digit_1) &  is.na(digit_2) & !is.na(digit_3) ~ digit_4 * 3,
        is.na(digit_1) & !is.na(digit_2)                   ~ digit_4 * 4
      ),
      digit_5     = case_when(
        !is.na(digit_1)                                     ~ digit_5 * 6, 
        is.na(digit_1) &  is.na(digit_2) &  is.na(digit_3) ~ digit_5 * 3,
        is.na(digit_1) &  is.na(digit_2) & !is.na(digit_3) ~ digit_5 * 4,
        is.na(digit_1) & !is.na(digit_2)                   ~ digit_5 * 5
      ),
      digit_6     = case_when(
        !is.na(digit_1)                                     ~ digit_6 * 7, 
        is.na(digit_1) &  is.na(digit_2) &  is.na(digit_3) ~ digit_6 * 4,
        is.na(digit_1) &  is.na(digit_2) & !is.na(digit_3) ~ digit_6 * 5,
        is.na(digit_1) & !is.na(digit_2)                   ~ digit_6 * 6
      ),
      digit_7     = case_when(
        !is.na(digit_1)                                     ~ digit_7 * 2, 
        is.na(digit_1) &  is.na(digit_2) &  is.na(digit_3) ~ digit_7 * 5,
        is.na(digit_1) &  is.na(digit_2) & !is.na(digit_3) ~ digit_7 * 6,
        is.na(digit_1) & !is.na(digit_2)                   ~ digit_7 * 7
      ),
      digit_8     = case_when(
        !is.na(digit_1)                                     ~ digit_8 * 3, 
        is.na(digit_1) &  is.na(digit_2) &  is.na(digit_3) ~ digit_8 * 6,
        is.na(digit_1) &  is.na(digit_2) & !is.na(digit_3) ~ digit_8 * 7,
        is.na(digit_1) & !is.na(digit_2)                   ~ digit_8 * 2
      ),
      digit_9     = case_when(
        !is.na(digit_1)                                     ~ digit_9 * 4, 
        is.na(digit_1) &  is.na(digit_2) &  is.na(digit_3) ~ digit_9 * 7,
        is.na(digit_1) &  is.na(digit_2) & !is.na(digit_3) ~ digit_9 * 2,
        is.na(digit_1) & !is.na(digit_2)                   ~ digit_9 * 3
      ),
      sum         = rowSums(across(c(digit_1, digit_2, digit_3, digit_4, digit_5, digit_6, digit_7, digit_8, digit_9)), na.rm = TRUE),
      check_digit = (11 - (sum - (11*(trunc(sum/11)))))) %>% 
    mutate(
      check_digit = ifelse(check_digit == 11, 0, ifelse(
        check_digit == 10, "K", check_digit
      ))
    ) %>% 
    mutate(
      var = paste0(var, check_digit)
    ) %>% 
    dplyr::select(
      -c("check_digit", "sum", starts_with("digit"))
    ) 
  
  return(data)
  
}