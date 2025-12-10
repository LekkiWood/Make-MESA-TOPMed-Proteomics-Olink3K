path_proteins = "/media/RawData/MESA/MESA-Multiomics/MESA-Multiomics_Proteomics/Olink/SMP_IntensityNormalized_20251005.csv"
#Mapping info
path_protein_info = "/media/RawData/MESA/MESA-Multiomics/MESA-Multiomics_Proteomics/Olink/Mapping_SMP_Plate_20251005.csv"
#Protein keys
path_protein_keys = "/media/RawData/MESA/MESA-Multiomics/MESA-Multiomics_Proteomics/Olink/MESAOlink3k_proteinKeys_03292023.csv"
#Bridging file
path_bridge= "/media/RawData/MESA/MESA-Phenotypes/MESA-Website-Phenos/MESA-SHARE_IDList_Labeled.csv"



proteins_raw <- data.table::fread(path_proteins)
protein_info <- data.table::fread(path_protein_info)
protein_keys <- data.table::fread(path_protein_keys)
bridge <- data.table::fread(path_bridge) |>
  dplyr::select(`SHARE ID Number`, `MESA Participant ID`) |>
  dplyr::rename(sidno = `SHARE ID Number`, idno = `MESA Participant ID`)

##################
##Initial prot file
##################

Initial_prots <- proteins_raw |>
  dplyr::left_join(protein_info, dplyr::join_by(SampleID))

initial_N_by_exam <- Initial_prots |>
  dplyr::group_by(Exam) |>
  dplyr::summarise(N_Pps = dplyr::n_distinct(SampleID))

##N OK

##################
##Initial prot file samples only
##################

Samples_IDs <- protein_info |>
  dplyr::filter(Sample_Type=="SAMPLE" & is.na(Note)) 

sample_prots <- proteins_raw |> 
  dplyr::filter(SampleID %in% Samples_IDs$SampleID)|>
  dplyr::left_join(protein_info, dplyr::join_by(SampleID))

samples_N_by_exam <- sample_prots |>
  dplyr::group_by(Exam) |>
  dplyr::summarise(N_Pps = dplyr::n_distinct(SampleID)). #This is OK


##################
##Used in script
##################

formatted_proteins <- proteins_raw |>
  #remove non-proteins (assays used for QC)
  dplyr::filter(OlinkID %in% protein_keys$OlinkID) |>
  #remove bridging samples |>
  dplyr::filter(SampleID %in% Non_bridging_samples$SampleID) |>
  #Remove QC failures
  dplyr::filter(QC_Warning !="EXCLUDED") |>
  dplyr::select(SampleID, OlinkID, NPX) |>
  tidyr::pivot_wider(id_cols=SampleID, names_from = OlinkID, values_from = NPX)|>
  #merge in exam and id info, using only info in mapping file (no protein assays)
  dplyr::left_join(dplyr::select(Non_bridging_samples, SampleID, sidno, Exam, Batch), 
                   dplyr::join_by(SampleID))



script_N_by_exam <- formatted_proteins |>
  dplyr::group_by(Exam) |>
  dplyr::summarise(N_Pps = dplyr::n_distinct(SampleID))

##This is too small

formatted_proteins2 <- proteins_raw |>
  #remove non-proteins (assays used for QC)
  dplyr::filter(OlinkID %in% protein_keys$OlinkID) |>
  #remove bridging samples |>
  dplyr::filter(SampleID %in% Non_bridging_samples$SampleID) |>
  #Remove QC failures
  #dplyr::filter(QC_Warning !="EXCLUDED") |>
  dplyr::select(SampleID, OlinkID, NPX) |>
  tidyr::pivot_wider(id_cols=SampleID, names_from = OlinkID, values_from = NPX)|>
  #merge in exam and id info, using only info in mapping file (no protein assays)
  dplyr::left_join(dplyr::select(Non_bridging_samples, SampleID, sidno, Exam, Batch), 
                   dplyr::join_by(SampleID))



script_N_by_exam2 <- formatted_proteins2 |>
  dplyr::group_by(Exam) |>
  dplyr::summarise(N_Pps = dplyr::n_distinct(SampleID))

##This is OK

missing_ids <- formatted_proteins2 |>
  dplyr::filter(!SampleID %in% formatted_proteins$SampleID) |>
  dplyr::pull(SampleID)

missing_ids_info <- Initial_prots |>
  dplyr::filter(SampleID %in% missing_ids)

table(missing_ids_info$QC_Warning)



########Try new exclusion

formatted_proteins3 <- proteins_raw |>
  #remove non-proteins (assays used for QC)
  dplyr::filter(OlinkID %in% protein_keys$OlinkID) |>
  #remove bridging samples |>
  dplyr::filter(SampleID %in% Non_bridging_samples$SampleID) |>
  #Remove QC failures
  dplyr::filter(is.na(QC_Warning) | QC_Warning !="EXCLUDED") |>
  dplyr::select(SampleID, OlinkID, NPX) |>
  tidyr::pivot_wider(id_cols=SampleID, names_from = OlinkID, values_from = NPX)|>
  #merge in exam and id info, using only info in mapping file (no protein assays)
  dplyr::left_join(dplyr::select(Non_bridging_samples, SampleID, sidno, Exam, Batch), 
                   dplyr::join_by(SampleID))



script_N_by_exam3 <- formatted_proteins3 |>
  dplyr::group_by(Exam) |>
  dplyr::summarise(N_Pps = dplyr::n_distinct(SampleID))











formatted_proteins <- proteins_raw |>
  #remove non-proteins (assays used for QC)
  dplyr::filter(OlinkID %in% protein_keys$OlinkID) |>
  #remove bridging samples |>
  dplyr::filter(SampleID %in% Non_bridging_samples$SampleID) |>
  #Remove QC failures
  dplyr::filter(QC_Warning !="EXCLUDED") |>
  dplyr::select(SampleID, OlinkID, NPX) |>
  tidyr::pivot_wider(id_cols=SampleID, names_from = OlinkID, values_from = NPX)|>
  #merge in exam and id info, using only info in mapping file (no protein assays)
  dplyr::left_join(dplyr::select(Non_bridging_samples, SampleID, sidno, Exam, Batch), 
                   dplyr::join_by(SampleID)) |>
  dplyr::left_join(bridge, dplyr::join_by(sidno))

check <- as.data.frame(table(protein_info$Plate)) |>
  dplyr::rename(Plate = Var1)

range(check$Freq)

####Check N

N_check <- Proteins_long |>
  dplyr::left_join(protein_info, dplyr::join_by(SampleID, Exam, sidno)) 

N_check2 <- N_check |>
  dplyr::group_by(Exam) |>
  dplyr::summarise(N_inc_sidno = dplyr::n_distinct(sidno),
                   N_inc_TOPID = dplyr::n_distinct(SampleID))

check_exam_miss <- N_check |>
  dplyr::filter(is.na(Exam))

temp <- protein_info |>
  dplyr::filter(SampleID=="TOP622073")

######Check

Non_bridging_samples_check <- protein_info |>
  dplyr::filter(Sample_Type=="SAMPLE" & is.na(Note))

temp2 <- Non_bridging_samples_check |>
  dplyr::filter(SampleID=="TOP622073")

temp3 <- proteins_raw |>
  #remove non-proteins (assays used for QC)
  dplyr::filter(OlinkID %in% protein_keys$OlinkID) |>
  #remove bridging samples |>
  dplyr::filter(SampleID %in% Non_bridging_samples_check$SampleID) |>  #Up to here - no control samples!
  #Remove QC failures
  dplyr::filter(QC_Warning !="EXCLUDED") |>
  dplyr::select(SampleID, OlinkID, NPX) |>
  tidyr::pivot_wider(id_cols=SampleID, names_from = OlinkID, values_from = NPX) |> #Up to here - no control samples!
  #merge in exam and id info, using only info in mapping file (no protein assays)
  dplyr::left_join(dplyr::select(Non_bridging_samples_check, SampleID, sidno, Exam, Batch), 
                   dplyr::join_by(SampleID)) 



temp4 <- temp3 |>
  dplyr::filter(SampleID=="TOP622073")

temp5 <- Proteins_long |>
  dplyr::filter(SampleID=="TOP622073")

{r}

#| label: tbl-HILIC-dupes 
#| tbl-cap: "Duplicate metabolite abundances in metabolites from HILIC assay, supplied by MESA DCC" 

knitr::kable(final_N_by_exam, format="latex")
