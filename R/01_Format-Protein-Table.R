build_protein_table_function <- function(path_proteins, path_protein_info, path_protein_keys, path_bridge)
  
{
  
  #----------------------------------------------------------#
  #---------------Read in files -----------------------------#
  #----------------------------------------------------------#
  
  #Intensity table
  proteins_raw <- data.table::fread(path_proteins)
  
  #Info table
  protein_info <- data.table::fread(path_protein_info)
  
  #Info table
  protein_keys <- data.table::fread(path_protein_keys)
  
  #Bridging file
  bridge <- data.table::fread(path_bridge) |>
    dplyr::select(`SHARE ID Number`, `MESA Participant ID`) |>
    dplyr::rename(sidno = `SHARE ID Number`, idno = `MESA Participant ID`)
  
  raw_protein_N_all <- length(unique(proteins_raw$OlinkID))
  
  raw_protein_N_proteins <- proteins_raw |>
    dplyr::filter(OlinkID %in% protein_keys$OlinkID) |>
    dplyr::summarise(unique_count = dplyr::n_distinct(OlinkID)) 
    
  
  #------------------------------------------------------------#
  #---------------Info for README -----------------------------#
  #------------------------------------------------------------#
  
  QC_info <- list(
    filenames = list(raw_proteins_file_name = path_proteins,
                     raw_protein_info_file_name = path_protein_info,
                     raw_bridgingfile_file_name = path_bridge,
                     raw_protein_keys_file_name = path_protein_keys
                     ),
    
    raw_inputs = list(raw_protein_N_all = raw_protein_N_all,
                          raw_protein_N_proteins = raw_protein_N_proteins
                          )
    )
    
    #----------------Outputs -----------------------------#
    
    list(
      
      QC_info_out = QC_info
      
    )
    
  
}