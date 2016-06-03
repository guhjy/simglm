library(shiny)
library(shinydashboard)
library(simglm)

options(useFancyQuotes = FALSE)

extract_needed_args <- function(func, remove_n = TRUE) {
  if(remove_n){
    formalArgs(func)[sapply(formals(func), 'is.symbol') == TRUE & 
                       formalArgs(func) != 'n']
  } else {
    formalArgs(func)[sapply(formals(func), 'is.symbol') == TRUE]
  }
}

server <- function(input, output, session) {
  
  output$beta <- renderUI({
    num_covs <- input$number_cov
    if(input$type_nested == 2) {
      num_covs <- num_covs + 1
    }
    if(input$incl_int) {
      num_covs <- num_covs + 1
    }
    beta_names <- paste('Beta cov', 1:num_covs, sep = '_')
    if(input$type_nested == 2) {
      beta_names <- c('Beta Time', beta_names)
    }
    if(input$incl_int) {
      beta_names <- c('Beta Int', beta_names)
    } 
    lapply(1:num_covs, function(i)
      div(style = 'display:inline-block',
          numericInput(paste0('beta', i), label = beta_names[i], value = 1, width = '75px'))
    )
  })
  
  output$mean_cov  <- renderUI({
    num_covs <- input$number_cov
    cov_names <- paste('Mean cov', 1:num_covs, sep = '_')
    lapply(1:num_covs, function(i) 
      div(style = 'display:inline-block', 
          numericInput(paste0('mean', i), label = cov_names[i], value = 0, width = '75px'))
    )
  })
  
  output$sd_cov <- renderUI({
    num_covs <- input$number_cov
    cov_names <- paste('SD cov', 1:num_covs, sep = '_')
    lapply(1:num_covs, function(i) 
      div(style = 'display:inline-block', 
          numericInput(paste0('sd', i), label = cov_names[i], value = 1, width = '75px'))
    )
  })
  
  output$type_cov <- renderUI({
    num_covs <- input$number_cov
    cov_names <- paste('Type cov', 1:num_covs, sep = '_')
    if(input$type_model == 1) {
      lapply(1:num_covs, function(i) 
        div(style = 'display:inline-block', 
            textInput(paste0('type', i), label = cov_names[i], value = 'single', width = '75px'))
      )
    } else {
      lapply(1:num_covs, function(i) 
        div(style = 'display:inline-block', 
            textInput(paste0('type', i), label = cov_names[i], value = 'lvl1', width = '75px'))
      )
    }
  })
  
  output$lvl2_err <- renderUI({
    if(input$type_model %in% c(2, 3) & input$type_nested == 2) {
      lapply(c('int', 'time'), function(i)
        div(style = 'display:inline-block',
            textInput(paste0('var_', i), label = paste0('Var ', i), value = '1', width = '75px')
        )
      )
    } else {
      if(input$type_model %in% c(2, 3) & input$type_nested == 1) {
        textInput('var_int', label = 'Var int', value = '1')
      }
    }
  })
  
  gen_code <- eventReactive(input$update, {
    if(input$type_model == 1) {
      n <- input$samp_size_lvl1
      error_var <- input$lvl1_err
      with_err_gen <- 'rnorm'
      if(input$incl_int) {
        fixed <- as.formula(paste0('~ 1 + ', 
                                   paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                         collapse = ' + ')))
      } else {
        fixed <- as.formula(paste0('~ 0 + ', 
                                   paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                         collapse = ' + ')))
      }
      num_betas <- input$number_cov
      if(input$incl_int) {
        num_betas <- num_betas + 1
      }
      beta <- sapply(1:num_betas, function(i) input[[paste0('beta', i)]])
      fixed_param <- beta
      
      num_cov <- input$number_cov
      mean_cov <- sapply(1:num_cov, function(i) input[[paste0('mean', i)]])
      sd_cov <- sapply(1:num_cov, function(i) input[[paste0('sd', i)]])
      type_cov <- sapply(1:num_cov, function(i) input[[paste0('type', i)]])
      
      cov_param <- list(mean = mean_cov,
                        sd = sd_cov,
                        var_type = type_cov)
      
      sim_reg(fixed = fixed, fixed_param = fixed_param, cov_param = cov_param,
              n = n, error_var = error_var, with_err_gen = with_err_gen,
              data_str = "single")
    } else {
      if(input$type_model == 2) {
        p <- input$samp_size_lvl1
        n <- input$samp_size_lvl2
        error_var <- input$lvl1_err
        with_err_gen <- 'rnorm'
        if(input$type_nested == 1) {
          random <- ~ 1
          data_str <- 'cross'
          ran_var <- input[['var_int']]
          random_param <- list(random_var = ran_var,
                               rand_gen = 'rnorm')
          if(input$incl_int) {
            fixed <- as.formula(paste0('~ 1 + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          } else {
            fixed <- as.formula(paste0('~ 0 + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          }
        } else {
          data_str <- 'long'
          random <- ~ 1 + time
          ran_var <- sapply(c('int', 'time'), function(i) input[[paste0('var_', i)]])
          random_param <- list(random_var = ran_var,
                               rand_gen = 'rnorm')
          if(input$incl_int) {
            fixed <- as.formula(paste0('~ 1 + time + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          } else {
            fixed <- as.formula(paste0('~ 0 + time + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          }
        }
        
        num_betas <- input$number_cov
        if(input$type_nested == 2) {
          num_betas <- num_betas + 1
        }
        if(input$incl_int) {
          num_betas <- num_betas + 1
        }
        beta <- sapply(1:num_betas, function(i) input[[paste0('beta', i)]])
        fixed_param <- beta
        
        num_cov <- input$number_cov
        mean_cov <- sapply(1:num_cov, function(i) input[[paste0('mean', i)]])
        sd_cov <- sapply(1:num_cov, function(i) input[[paste0('sd', i)]])
        type_cov <- sapply(1:num_cov, function(i) input[[paste0('type', i)]])
        
        cov_param <- list(mean = mean_cov,
                          sd = sd_cov,
                          var_type = type_cov)
        sim_reg(fixed = fixed, random = random, 
                fixed_param = fixed_param, 
                random_param = random_param, cov_param = cov_param, 
                k = NULL, n = n, p = p,
                error_var = error_var, with_err_gen = with_err_gen,
                data_str = data_str, unbal = FALSE)
      } else {
        p <- input$samp_size_lvl1
        n <- input$samp_size_lvl2
        k <- input$samp_size_lvl3
        error_var <- input$lvl1_err
        with_err_gen <- 'rnorm'
        if(input$type_nested == 1) {
          random <- ~ 1
          data_str <- 'cross'
          ran_var <- input[['var_int']]
          random_param <- list(random_var = ran_var,
                               rand_gen = 'rnorm')
          if(input$incl_int) {
            fixed <- as.formula(paste0('~ 1 + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          } else {
            fixed <- as.formula(paste0('~ 0 + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          }
        } else {
          data_str <- 'long'
          random <- ~ 1 + time
          ran_var <- sapply(c('int', 'time'), function(i) input[[paste0('var_', i)]])
          random_param <- list(random_var = ran_var,
                               rand_gen = 'rnorm')
          if(input$incl_int) {
            fixed <- as.formula(paste0('~ 1 + time + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          } else {
            fixed <- as.formula(paste0('~ 0 + time + ', 
                                       paste(paste('cov', 1:input$number_cov, sep = '_'), 
                                             collapse = ' + ')))
          }
        }
        
        num_betas <- input$number_cov
        if(input$type_nested == 2) {
          num_betas <- num_betas + 1
        }
        if(input$incl_int) {
          num_betas <- num_betas + 1
        }
        beta <- sapply(1:num_betas, function(i) input[[paste0('beta', i)]])
        fixed_param <- beta
        
        num_cov <- input$number_cov
        mean_cov <- sapply(1:num_cov, function(i) input[[paste0('mean', i)]])
        sd_cov <- sapply(1:num_cov, function(i) input[[paste0('sd', i)]])
        type_cov <- sapply(1:num_cov, function(i) input[[paste0('type', i)]])
        
        cov_param <- list(mean = mean_cov,
                          sd = sd_cov,
                          var_type = type_cov)
        random3 <- ~ 1
        random_param3 <- list(random_var = input$lvl3_err,
                              rand_gen = 'rnorm')
        
        sim_reg(fixed, random, random3, fixed_param, random_param, 
                random_param3, cov_param, k,n, p, error_var, with_err_gen, 
                data_str = data_str)
      }
    }
    
  })
  
  output$gen_examp <- renderDataTable({
    datatable(gen_code())
  })
  
  output$gen_examp_code <- renderUI({
    if(input$type_model == 1) {
      str1 <- paste0('n <- ', input$samp_size_lvl1)
      str2 <- paste0('error_var <- ', input$lvl1_err)
      str3 <- paste0('with_err_gen <- ', 'rnorm')
      if(input$incl_int) {
        str4 <- paste0('fixed <- ~ 1 + ', paste(paste('cov', 1:input$number_cov, sep = '_'),
                                                collapse = ' + '))
      } else {
        str4 <- paste0('fixed <- ~ 0 + ', paste(paste('cov', 1:input$number_cov, sep = '_'),
                                                collapse = ' + '))
      }
      num_betas <- input$number_cov
      if(input$incl_int) {
        num_betas <- num_betas + 1
      }
      beta <- sapply(1:num_betas, function(i) input[[paste0('beta', i)]])
      
      num_cov <- input$number_cov
      mean_cov <- sapply(1:num_cov, function(i) input[[paste0('mean', i)]])
      sd_cov <- sapply(1:num_cov, function(i) input[[paste0('sd', i)]])
      type_cov <- sapply(1:num_cov, function(i) input[[paste0('type', i)]])

      str5 <- paste0('fixed_param <- c(', paste(beta,
                                                collapse = ', '), ')')
      str6 <- paste0('cov_param <- list(mean = c(', 
                     paste(mean_cov,
                           collapse = ','),
                     '), sd = c(',
                     paste(sd_cov,
                           collapse = ','),
                     '), var_type = c(',
                     paste(sQuote(type_cov),
                           collapse = ','),
                     '))')
      str7 <- 'temp_single <- sim_reg(fixed = fixed, fixed_param = fixed_param, cov_param = cov_param, <br/>
      n = n, error_var = error_var, with_err_gen = with_err_gen, <br/>
      data_str = "single")'
      HTML(paste(str1, str2, str3, str4, str5, str6, str7, sep = '<br/>'))
    } else {
      if(input$type_model == 2) {
        str1 <- paste0('n <- ', input$samp_size_lvl2)
        str_p <- paste0('p <- ', input$samp_size_lvl1)
        str2 <- paste0('error_var <- ', input$lvl1_err)
        str3 <- paste0('with_err_gen <- ', '"rnorm"')
        if(input$type_nested == 1) {
          str_random <- 'random <- ~ 1'
          str_data <- "data_str <- 'cross'"
          ran_var <- input[['var_int']]
          str_randparam <- paste0('random_param <- list(random_var = c(',
                                  as.numeric(ran_var),
                                  '), rand_gen = ',
                                  '"rnorm"', 
                                  ')')
          if(input$incl_int) {
            str4 <- paste0('fixed <- ~ 1 + ', paste(paste('cov', 1:input$number_cov, sep = '_'),
                                                    collapse = ' + '))
          } else {
            str4 <- paste0('fixed <- ~ 0 + ', paste(paste('cov', 1:input$number_cov, sep = '_'),
                                                    collapse = ' + '))
          }
        } else {
          str_data <- "data_str <- 'long'"
          str_random <- 'random <- ~ 1 + time'
          ran_var <- sapply(c('int', 'time'), function(i) input[[paste0('var_', i)]])
          str_randparam <- paste0('random_param <- list(random_var = c(',
                                  paste(ran_var,
                                        collapse = ', '),
                                  '), rand_gen = ',
                                  '"rnorm"', 
                                  ')')
          if(input$incl_int) {
            str4 <- paste0('fixed <- ~ 1 + time + ', 
                           paste(paste('cov', 1:input$number_cov, sep = '_'),
                                 collapse = ' + '))
          } else {
            str4 <- paste0('fixed <- ~ 0 + time + ', 
                           paste(paste('cov', 1:input$number_cov, sep = '_'),
                                 collapse = ' + '))
          }
        }
        num_betas <- input$number_cov
        if(input$type_nested == 2) {
          num_betas <- num_betas + 1
        }
        if(input$incl_int) {
          num_betas <- num_betas + 1
        }
        beta <- sapply(1:num_betas, function(i) input[[paste0('beta', i)]])
        
        num_cov <- input$number_cov
        mean_cov <- sapply(1:num_cov, function(i) input[[paste0('mean', i)]])
        sd_cov <- sapply(1:num_cov, function(i) input[[paste0('sd', i)]])
        type_cov <- sapply(1:num_cov, function(i) input[[paste0('type', i)]])
        
        str5 <- paste0('fixed_param <- c(', paste(beta,
                                                  collapse = ', '), ')')
        str6 <- paste0('cov_param <- list(mean = c(', 
                       paste(mean_cov,
                             collapse = ','),
                       '), sd = c(',
                       paste(sd_cov,
                             collapse = ','),
                       '), var_type = c(',
                       paste(sQuote(type_cov),
                             collapse = ','),
                       '))')
        str7 <- 'temp_nested <- sim_reg(fixed = fixed, random = random, fixed_param = fixed_param, <br/>
      random_param = random_param, cov_param = cov_param, k = NULL, n = n, p = p, <br/>
      error_var = error_var, with_err_gen = with_err_gen, data_str = data_str, unbal = FALSE)'
        HTML(paste(str1, str_p, str2, str3, str4, str_random, 
                   str5, str_randparam, str6, str_data, str7, sep = '<br/>'))
      } 
      else {
        str1 <- paste0('n <- ', input$samp_size_lvl2)
        str_p <- paste0('p <- ', input$samp_size_lvl1)
        str_k <- paste0('k <- ', input$samp_size_lvl3)
        str2 <- paste0('error_var <- ', input$lvl1_err)
        str3 <- paste0('with_err_gen <- ', '"rnorm"')
        if(input$type_nested == 1) {
          str_random <- 'random <- ~ 1'
          str_data <- "data_str <- 'cross'"
          ran_var <- input[['var_int']]
          str_randparam <- paste0('random_param <- list(random_var = c(',
                                  as.numeric(ran_var),
                                  '), rand_gen = ',
                                  '"rnorm"', 
                                  ')')
          if(input$incl_int) {
            str4 <- paste0('fixed <- ~ 1 + ', paste(paste('cov', 1:input$number_cov, sep = '_'),
                                                    collapse = ' + '))
          } else {
            str4 <- paste0('fixed <- ~ 0 + ', paste(paste('cov', 1:input$number_cov, sep = '_'),
                                                    collapse = ' + '))
          }
        } else {
          str_data <- "data_str <- 'long'"
          str_random <- 'random <- ~ 1 + time'
          ran_var <- sapply(c('int', 'time'), function(i) input[[paste0('var_', i)]])
          str_randparam <- paste0('random_param <- list(random_var = c(',
                                  paste(ran_var,
                                        collapse = ', '),
                                  '), rand_gen = ',
                                  '"rnorm"', 
                                  ')')
          if(input$incl_int) {
            str4 <- paste0('fixed <- ~ 1 + time + ', 
                           paste(paste('cov', 1:input$number_cov, sep = '_'),
                                 collapse = ' + '))
          } else {
            str4 <- paste0('fixed <- ~ 0 + time + ', 
                           paste(paste('cov', 1:input$number_cov, sep = '_'),
                                 collapse = ' + '))
          }
        }
        num_betas <- input$number_cov
        if(input$type_nested == 2) {
          num_betas <- num_betas + 1
        }
        if(input$incl_int) {
          num_betas <- num_betas + 1
        }
        beta <- sapply(1:num_betas, function(i) input[[paste0('beta', i)]])
        
        num_cov <- input$number_cov
        mean_cov <- sapply(1:num_cov, function(i) input[[paste0('mean', i)]])
        sd_cov <- sapply(1:num_cov, function(i) input[[paste0('sd', i)]])
        type_cov <- sapply(1:num_cov, function(i) input[[paste0('type', i)]])
        
        str5 <- paste0('fixed_param <- c(', paste(beta,
                                                  collapse = ', '), ')')
        str6 <- paste0('cov_param <- list(mean = c(', 
                       paste(mean_cov,
                             collapse = ','),
                       '), sd = c(',
                       paste(sd_cov,
                             collapse = ','),
                       '), var_type = c(',
                       paste(sQuote(type_cov),
                             collapse = ','),
                       '))')
        str_random3 <- 'random3 <- ~ 1'
        str_randparam3 <- paste0('random_param3 <- list(random_var = c(',
                                 input$lvl3_err, '), rand_gen = "rnorm")')
        str7 <- 'temp_nested <- sim_reg(fixed, random, random3, fixed_param, random_param, <br/>
                random_param3, cov_param, k,n, p, error_var, with_err_gen, <br/>
                data_str = data_str)'
        HTML(paste(str1, str_p, str_k, str2, str3, str4, str_random, str_random3,
                   str5, str_randparam, str_randparam3, str6, str_data, str7, 
                   sep = '<br/>'))
      }
      
    }
    
  })
  
}