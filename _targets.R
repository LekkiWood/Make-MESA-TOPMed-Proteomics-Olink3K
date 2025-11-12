library('targets')
library('tarchetypes')
library(crew)
tar_option_set(controller = crew_controller_local(workers = 10)) 
Sys.setenv(VROOM_CONNECTION_SIZE = as.character(10 * 1024 * 1024)) #For any large datasets

####This runs a workflow for cleaning the MESA TOPMed multi-omics project proteomics data (O-link), 
#### formatting it into the following format: wide for metabolites & long for exams, 
#### and providing basic quality control (QC) metrics



tar_option_set(packages = c("dplyr", "tidyr", "tibble", "readr", "data.table", "bit64", 
                            "foreign", "quarto", "rlang", "purrr", "rcompanion"))

tar_source("/media/Analyses/Make-MESA-TOPMed-Proteomics-Olink3K/R")

list(
  #---------------------------------------------------------------------------------------#
  #--------------------------------1. Build proteomics table------------------------------#
  #---------------------------------------------------------------------------------------#

  #Protein intensities
  tar_target(path_proteins, "/media/RawData/MESA/MESA-Multiomics/MESA-Multiomics_Proteomics/Olink/SMP_IntensityNormalized_20251005.csv", format = "file"),
  #Mapping info
  tar_target(path_protein_info, "/media/RawData/MESA/MESA-Multiomics/MESA-Multiomics_Proteomics/Olink/Mapping_SMP_Plate_20251005.csv", format = "file"),
  #Protein keys
  tar_target(path_protein_keys, "/media/RawData/MESA/MESA-Multiomics/MESA-Multiomics_Proteomics/Olink/MESAOlink3k_proteinKeys_03292023.csv", format = "file"),
  
  #Bridging file
  tar_target(path_bridge,"/media/RawData/MESA/MESA-Phenotypes/MESA-Website-Phenos/MESA-SHARE_IDList_Labeled.csv", format = "file"),
  
  #Run function
  tar_target(build_proteins_out,   
             build_protein_table_function(
               path_proteins = path_proteins,
               path_protein_info = path_protein_info,
               path_protein_keys = path_protein_keys,
               path_bridge = path_bridge)
  ),
  
  #Save outputs
  tar_target(build_proteins_QC, build_proteins_out$QC_info_out),
  
  
  #---------------------------------------------------------------------------------------#
  #--------------------------------Quarto output------------------------------------------#
  #---------------------------------------------------------------------------------------#
  
  tarchetypes::tar_quarto(
    build_proteins_quarto,
    path = "/media/Analyses/Make-MESA-TOPMed-Proteomics-Olink3K/Make-MESA-TOPMed-Protein-Table-README.qmd",
    quiet = FALSE
  )
)
  
  