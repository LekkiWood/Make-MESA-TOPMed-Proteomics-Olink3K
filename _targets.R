library('targets')
library('tarchetypes')
library(crew)
tar_option_set(controller = crew_controller_local(workers = 10)) 
Sys.setenv(VROOM_CONNECTION_SIZE = as.character(10 * 1024 * 1024)) #For any large datasets

####This runs a workflow for cleaning the MESA TOPMed multi-omics project proteomics data (O-link), 
#### formatting it into the following format: wide for metabolites & long for exams, 
#### and providing basic quality control (QC) metrics



tar_option_set(packages = c("dplyr", "tidyr", "tibble", "readr", "data.table", "bit64", 
                            "foreign", "quarto", "rlang", "purrr", "rcompanion", "knitr", "gtsummary", "gt"))

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
  #QC info
  tar_target(build_proteins_QC, build_proteins_out$QC_info_out),
  #Proteins
  tar_target(Proteins_long, build_proteins_out$Formatted_proteins_out),
  #N in formatted file by exam
  tar_target(Proteins_long_N, build_proteins_out$N_by_exam),
  
  #Protein table (long form) as csv file
  tar_target(long_proteintable_filename, paste0("MESA_TOPMed_Protein_Longform_", Sys.Date(), ".csv")),
  tar_target(save_long_protein_table_csv,
             {
               out_dir  <- "outputs"
               dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
               out_path <- file.path(out_dir, long_proteintable_filename)
               readr::write_csv(Proteins_long, out_path)
               out_path
             },
             format = "file"
  ),
  
  #---------------------------------------------------------------------------------------#
  #--------------------------------2. Build mapping file ---------------------------------#
  #---------------------------------------------------------------------------------------#
  
  

  #QC info
  tar_target(protein_info, QC_proteins_function(path_proteins = path_proteins,
                                                path_protein_info = path_protein_info,
                                                path_protein_keys = path_protein_keys,
                                                Proteins_long = Proteins_long)),
  tar_target(Protein_mapping_file, protein_info$final_proteins_mapping),
  
  #Protein table (long form) as csv file
  tar_target(mappingfile_filename, paste0("MESA_TOPMed_Protein_Mapping_", Sys.Date(), ".csv")),
  tar_target(save_protein_mappingfile_csv,
             {
               out_dir  <- "outputs"
               dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
               out_path <- file.path(out_dir, mappingfile_filename)
               readr::write_csv(Protein_mapping_file, out_path)
               out_path
             },
             format = "file"
  ),
  
  #---------------------------------------------------------------------------------------#
  #--------------------------2. Build final clean proteins file --------------------------#
  #---------------------------------------------------------------------------------------#
  
  

  #Build proteins
  tar_target(proteins_clean, final_proteins_function(Proteins_long = Proteins_long, 
                                                     QC_file = Protein_mapping_file)
  ),
    

  #Save proteins
  tar_target(Proteins_long_clean, proteins_clean$Final_proteins),
  #N in cleaned & formagtted file by exam
  tar_target(Proteins_clean_N, proteins_clean$N_by_exam),
  
  #Protein table (long form) as csv file
  tar_target(cleanproteinfile_filename, paste0("MESA_TOPMed_Proteintable_Clean_", Sys.Date(), ".csv")),
  tar_target(save_cleanproteinfile_csv,
             {
               out_dir  <- "outputs"
               dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
               out_path <- file.path(out_dir, cleanproteinfile_filename)
               readr::write_csv(Proteins_long_clean, out_path)
               out_path
             },
             format = "file"
  ),
  
  
  #---------------------------------------------------------------------------------------#
  #--------------------------------Quarto output------------------------------------------#
  #---------------------------------------------------------------------------------------#
  
  tarchetypes::tar_quarto(
    build_proteins_quarto,
    path = "/media/Analyses/Make-MESA-TOPMed-Proteomics-Olink3K/Make-MESA-TOPMed-Protein-Table-README.qmd",
    quiet = FALSE
  )
)
  
  