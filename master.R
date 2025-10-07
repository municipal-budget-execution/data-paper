# ---------------------------------------------------------------------------- #
#                   Budget Execution Brazil: replication package               #
#                                   World Bank - DIME                          #
#                                                                              #
# ---------------------------------------------------------------------------- #
# ---------------------------------------------------------------------------- #
# ++++++++++++++++++++++++ TABLE OF CONTENTS +++++++++++++++++++++++++++++++++ #
#                                                                              #
#        1) SETUP    : general settings, set directories, and load data.       #
#        2) FUNCTIONS: here, you can find the list of all functions created.   #  
#                                                                              #
# **************************************************************************** #

# 0: Setting R ----

{
  { # 0.1: Prepare the workspace 
    
    # Clean the workspace
    rm(list=ls()) 
    
    # Free Unused R memory
    gc()
    
    # Options for avoid scientific notation
    options(scipen = 9999)
    
    # Set the same seed
    set.seed(123)
    
  }
  
  { # 0.2: Loading the packages
    
    # list of package needed
    packages <- 
      c( 
        "data.table",
        "ggplot2",
        "ggpubr",
        "modelsummary",
        "tinytex",
        "DescTools",
        "binsreg",
        "basedosdados",
        "ggtext",
        "dplyr"
        )
    
    # If the package is not installed, then install it 
    if (!require("pacman")) install.packages("pacman")
    
    # Load the packages 
    pacman::p_load(packages, character.only = TRUE, install = TRUE)
    
  }

  { # 0.3: Set billing - Bigquery
  
    set_billing_id("budget-execution-procurement")
  
  }
}

# 1: Setting Working Directories ----

{
  { # Setting path
    
    if (Sys.getenv("USERNAME") == "natha") { # Author
      
      print("Nathalia has been selected")
      
      dropbox_dir  <- "C:\\Users\\natha\\Dropbox\\MiDES-data-paper-replication"
      github_dir   <- "C:\\Users\\natha\\OneDrive\\Documentos\\GitHub\\data-paper"
      
    } else if (Sys.getenv("USER") == "ruggerodoino") { # RA (World Bank-DIME)'
      
      print("Ruggero has been selected")
      
      dropbox_dir  <- ""
      github_dir   <- ""
      
    } else if (Sys.getenv("USERNAME") == "wb463689") { # Author (World Bank-DIME)
      
      print("Thiago (WB) has been selected")
      
      dropbox_dir  <- ""
      github_dir   <- ""
      
    } else if (Sys.getenv("USER") == "thiagoscott") { # Author (World Bank-DIME)
      
      print("Thiago (WB) has been selected")
      
      dropbox_dir  <- "/Users/thiagoscott/Dropbox/MiDES-data-paper-replication"
      github_dir   <- "/Users/thiagoscott/Documents/GitHub/data-paper"
      
    } else if (Sys.getenv("USER") == "rdahis") { # Author (Monash University)
      
      print("Ricardo (Monash) has been selected")
      
      dropbox_dir  <- "/Users/rdahis/Monash Uni Enterprise Dropbox/Ricardo Dahis/Academic/Papers/MiDES-data-paper-replication"
      github_dir   <- "/Users/rdahis/Monash Uni Enterprise Dropbox/Ricardo Dahis/Academic/Papers/MiDES-data-paper-repository"
      
    }
      
  }
 
  { # Set working directories
    
    # DATA
    input <- file.path(dropbox_dir, "Data/Raw")

    # OUTPUTS
    graph_output <- file.path(dropbox_dir, "Output/Figures")
    table_output <- file.path(dropbox_dir, "Output/Tables")
    
    # CODE
    function_code <- file.path(github_dir, "Functions")

  }
}

# 1: Load functions ----

{
  
  invisible(sapply(list.files(function_code, full.names = TRUE), source, .GlobalEnv))
  
}

# 2: Load the data ----

{
  
  # We load the data
  # dataset at the municipality-by-year level, and it includes three main sets of variables: 
  # 1) measures of payment delay for procurement (avg delay, % above 30 days, % above 60 days...); 
  # 2) measures of how our aggregates of budget activities (e.g. commitments or payments) deviate from a Treasury database from Brazil -- these are to assess the quality of our data; 
  # 3) municipality fixed characteristics such as population, per capita gdp, ...
  data_munic = fread(file.path(input, "full_budget_execution_index.csv"), 
                     showProgress = TRUE,
                     encoding = "Latin-1")
  
  # Merge with home bias data
  home_bias <- fread(file.path(input, "home_bias.csv"))
  home_bias = home_bias %>%
    subset(vencedor == 1)
  setnames(
    home_bias,
    c("municipality", "state", "year", "winner", "same_municipality", "same_state")
  )
  data_munic <- merge(data_munic, home_bias, 
              by = c("municipality", "state", "year"), 
              all.x = TRUE)
  
}

# 3: Run the code ----

{
  
  # 3.1: this code generates CDFs and Histogram of average delay
  source(file.path(github_dir, "fig_reg_delay_payment.R"))
  
  # 3.2: this code generates the histogram of non-competitive tenders
  source(file.path(github_dir, "example_paper.R"))
  
  # 3.3: this code generates the regressions of local purchases on municipality characteristics and fixed effects
  source(file.path(github_dir, "home_bias_regressions.R"))
  
  
}
