ldats_wrapper <- function(data_list, seed, ntopics, ncpts, formulas, nit = 100) {
  
 tictoc::tic()  
  
  data_list$covariates <- as.data.frame( data_list$covariates)
  
  thislda <- LDATS::LDA_set_user_seeds(data_list$abundance, topics = ntopics, seed = seed)
  
  
  if(formulas == "time") {
    
    thists <-  LDATS::TS_on_LDA(LDA_models = thislda, document_covariate_table = data_list$covariates, nchangepoints = ncpts, formulas = c(~ year), weights =LDATS::document_weights(data_list$abundance), timename = "year", control = list(nit = nit))
    
  } else (
    
    thists <-  LDATS::TS_on_LDA(LDA_models = thislda, document_covariate_table = data_list$covariates, nchangepoints = ncpts, formulas = c(~ 1), weights =LDATS::document_weights(data_list$abundance), timename = "year", control = list(nit = nit, magnitude = 4))
    
  )
  timing <- tictoc::toc()  
  
  return(list(data = data_list,
              lda = thislda,
              ts = thists,
              timing = timing))
  
}