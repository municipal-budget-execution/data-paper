clean_string <- function(data, string) {
  
  require(stringi)
  require(stringr)
  
  data <- data %>% 
    
    mutate(
      new_string = str_to_upper({{string}})   ,
      new_string = gsub("\\s", "", new_string),
      new_string = gsub("[^[:alpha:][:alnum:]]", "", new_string),
      new_string = stri_trans_general(new_string,"Latin-ASCII")
    ) %>% 
    select(
      - {{string}}
    )
  
  return(data)
  
}
