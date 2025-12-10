sidno_by_id <- as.data.frame(table(formatted_proteins$sidno, formatted_proteins$Exam)) |>
  dplyr::rename(sidno = Var1,
                Exam = Var2) |>
  dplyr::arrange(Freq)

freq_freq <- subset(sidno_by_id, Freq > 1)

check1 <- subset(formatted_proteins, sidno==10380 & Exam==1)
check2 <- subset(protein_info, SampleID=="TOP185534" | SampleID=="TOP490160")