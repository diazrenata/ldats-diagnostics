library(drake)
library(MATSS)
library(LDATS)
library(matssldats)
source(here::here("fxns", "ldats_wrapper.R"))
## make sure the package functions in MATSS and matssldats are loaded in as
##   dependencies
expose_imports(MATSS)
expose_imports(matssldats)


seed <- 1977

ncpts <- c(0:4)

ntopics <- c(2, 3, 6, 12)

forms <- c("intercept", "time")

nits <- c(100, 1000, 10000)


pipeline <- drake_plan(
  portal_annual = get_portal_annual_data(),
  models = target(ldats_wrapper(portal_annual, seed = sd, ntopics = k, ncpts = cpts, formulas = form, nit = nbits),
                  transform = cross(sd = !!seed, k = !!ntopics,
                                    cpts = !!ncpts, form = !!forms, nbits = !!nits)),
  all_models = target(MATSS::collect_analyses(list(models)),
                        transform = combine(models))
)


## Set up the cache and config
db <- DBI::dbConnect(RSQLite::SQLite(), here::here("drake", "drake-cache.sqlite"))
cache <- storr::storr_dbi("datatable", "keystable", db)


## View the graph of the plan
if (interactive())
{
  config <- drake_config(pipeline, cache = cache)
  sankey_drake_graph(config, build_times = "none")  # requires "networkD3" package
  vis_drake_graph(config, build_times = "none")     # requires "visNetwork" package
}


## Run the pipeline
nodename <- Sys.info()["nodename"]
if(grepl("ufhpc", nodename)) {
  library(future.batchtools)
  print("I know I am on SLURM!")
  ## Run the pipeline parallelized for HiPerGator
  future::plan(batchtools_slurm, template = "slurm_batchtools.tmpl")
  make(pipeline,
       force = TRUE,
       cache = cache,
       cache_log_file = here::here("drake", "cache_log.txt"),
       verbose = 2,
       parallelism = "future",
       jobs = 128,
       caching = "master") # Important for DBI caches!
} else {
  # Run the pipeline on a single local core
  system.time(make(pipeline, cache = cache, cache_log_file = here::here("drake", "cache_log.txt")))
}
