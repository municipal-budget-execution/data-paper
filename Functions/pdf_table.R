pdf_table <- function(table, file_name) {
  
  
  if (file.exists(file_name)) {
    
    unlink(file_name)
    
  }
  
  for (j in 1:length(table)) { # loop over the length of each table 
    
    if (length(grep("caption", (table)[j]) == 1) |
        length(grep("Note", (table)[j]) == 1)) {
      
      print("Caption deleted")
      
    } else {
      
      if (j == 1) {
        
        cat("\\documentclass[border=10pt]{standalone}", "\n", file = file_name, append = "TRUE")
        cat("\\usepackage{varwidth}", "\n", file = file_name, append = "TRUE")
        cat("\\usepackage{booktabs}", "\n", file = file_name, append = "TRUE")
        cat("\\begin{document}", "\n", file = file_name, append = "TRUE")
        cat("\\begin{varwidth}{2000pt}", "\n", file = file_name, append = "TRUE")
        
      }
      
      cat((table)[j], "\n", file = file_name, append = "TRUE")
      
      if (j == length(table)) {
        
        cat("\\end{varwidth}", "\n", file = file_name, append = "TRUE")
        cat("\\end{document}", "\n", file = file_name, append = "TRUE")
        
      }
    }
    
  }
  
  pdflatex(
    file_name
  )
}