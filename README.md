# MERCI: tracing of mitochondrion transfer between single cancer and T cells
MERCI contains two modules:MERCI-mtSNP.py for calling mtSNVs and MERCI R package for predicting the mitochondrial recipient cells and their mitochondrial compositions. 

## MERCI-mtSNP

**MERCI-mtSNP is written in Python3, with the following dependencies:** 

- pandas
- numpy
- pysam
- matplotlib

Please make sure all dependency modules are installed before usiung MERCI-mtSNP.

### Usage
**Type python MERCI-mtSNP.py -h to display all the commandline options:**

| Parameters | Description |
| ------------- | ------------- |
| -h, --help | show this help message and exit |
| -D DATATYPE, --dataType=DATATYPE | The data type of sequencing data. One of '10x_scRNA-seq'(default), 'smart-seq2', 'bulk_ATAC-seq', 'scATAC-seq', or 'bulk_RNA-seq'. |
| -o DIRECTORY, --output=DIRECTORY | Output directory for intermediate and final outputs. |
| -S SAMPLEID , --sampleID=SAMPLEID | the sample identifier, also serve as the prefix of output file. if not given, the names of all intermediate or final output files will be automatically set as sampleX. |
| -b PATH_BAM, --Bamfile=PATH_BAM | Input bam file for MT mutation calling |
| -f PATH_FA, --fastafile=PATH_FA | The fasta data of genome reference sequence in the used reference genome file, usually named as XXX.fa |
| -c PATH_BARCODES, --CellBarcode=PATH_BARCODES | Only work for 10x_scRNA-seq data type, the directory where cell barcodes file (barcodes.tsv.gz or barcodes.tsv) generated by cell ranger exists in |
| -M MQUALITY, --MQcutoff=MQUALITY | The lowest alignment quality that are accepted, the reads with alignment scores below the given value will be discarded, default=5 for scATAC-seq or bulk ATAC-seq, default=255 for other dataTypes |
| -B QCUTOFF, --BQcutoff=QCUTOFF | The base quality cutoff, only alleles with BQ higher than this value will be retained, default=15 for 10x_scRNA-seq, default=25 for other dataTypes |
| -l LN, --ln=LN | Only work for 10x_scRNA-seq data type, the maximum length of genomic region for SNP clusters, reads supporting multiple variants within a small genomic region (ln bp) will be removed, default=5 |
| -m MINC, --minC=MINC | For all data types except 10x_scRNA-seq, A threshold for coverage, the faction of MT genome that was covered by reads no less than this value will be recorded on the generated coverage figure, default=1 |

### Input data format
The processed .bam file generated by alignment software (supporting Cell Ranger, STAR and Bowtie2) is used as the input of MERCI-mtSNP. Make sure the index .bai file is included with .bam file. The fasta file (.fa) in the reference genome folder (essential input for alignment tools) is also needed for MERCI-mtSNP.For 10x scRNA-seq data, the directory of the cell barcodes file generated by Cell Ranger  is needed to provide.

Currently MERCI-mtSNP works for 10x scRNA-seq, smart-seq2, RNA-seq, single cell or bulk ATAC-seq  data.

### Example of calling mtSNV from 10x scRNA-seq data:
**Assume the sample id is X, and Cell Ranger alignment output is generated in directory: /X/cellranger/outs. The path of fasta file is: /refdata-cellranger-mm10-2.1.0/fasta/genome.fa**
> python MERCI-mtSNP.py -D 10x_scRNA-seq \\  
> -o /X/output \\  
> -S X \\  
> -b /X/cellranger/outs/possorted_genome_bam.bam \\  
> -f /refdata-cellranger-mm10-2.1.0/fasta/genome.fa \\  
> -c /X/outs/filtered_feature_bc_matrix

### Example of calling mtSNV from a single cell ATAC-seq data:
**Also assume the sample id is X, and fastq file is aligned using Bowtie2 to the hg38 reference genome. The path file of alignment .bam file /X/alignment/X.sort.bam. The path of fasta file is: /UCSC/hg38/Sequence/WholeGenomeFasta/genome.fa**
> python MERCI-mtSNP.py -D scATAC-seq \\  
> -o /X/output \\  
> -S X \\  
> -b /X/alignment/X.sort.bam \\  
> -f /UCSC/hg38/Sequence/WholeGenomeFasta/genome.fa

___*Note: if the folder of .bam file does not contain its .bai index file, the user needs first to generate .bai file. For example using a simple command of samtools to create the bam index file: samtools index *.bam.___

### Output files:
The output directory contains two main output files: *.MT_variants.txt and *.MT_Coverage.csv file (*.Coverage_Cell.csv for 10x scRNA-seq data).  
The *.MT_variants.txt contains the annotated information of retrieved mtSNVs, *.MT_Coverage.csv or *.Coverage_Cell.csv records the coverage information in mitochondrial genome for each cell or sample.


## MERCI R package
### Install MERCI package
> library(devtools)  
> install_github(repo='shyhihihi/MERCI/MERCI')  

___*Note: When the system reminds you to update dependent packages, we recommend not to update___
### Usage
**This text will use a benchmark example data to illustrate how to use MERCI package**  
After the MERCI package is successfully installed, load the package.
> library(MERCI)  

Read the file of mitochondrial variants (*.MT_variants.txt’) called from MERCI-mtSNP. Here I prepared an example data ‘example.MT_variants.txt’. (User can find the fire in the data directory of this repository)
> varFile  <- './example.MT_variants.txt' ;  
> mtSNV_table <- readMTvar_10x(varFile, minReads=1000) ;  

varFile is the path of *.MT_variants.txt’, and minReads=1000 indicates that only Cell with MT reads > 1000 will be returned. readMTvar_10x  function works only for the variant file of 10x scRNA-seq data. If the user used other datatypes, such as ATAC-seq, smart-seq2 or bulk RNA-seq, etc., please use the code below:
> varFile  <- '. / XXX.MT_variants.txt'  
> MT_variants <- readMTvar(varFile, cellname = "XXX") 

### MERCI LOO for real-world application
**We first show how to run MERCI LOO pipeline, which means there is no reference data of non-receivers provided**  
Assuming T cells are MT donor cells and the population of cancer cells is a mixture of receivers and non-receivers. In this example data, we mixed 300 CC (receiver) and 500 MC (non-receiver) cancer cells. Load the cell information data:
> load('. /cell_info.RData')  
> T_cells <- cell_info$cell_name[cell_info$cell_type=='T cell']  
> Cancer_cells <- cell_info$cell_name[cell_info$cell_type=='cancer cell']  

Read the file of mitochondrial read-coverage generated by MERCI-mtSNP.
> CoverFile <- './example.Coverage_Cell.csv'  
> selected_Cells <- c(T_cells, Cancer_cells)  
> MTcoverage_inf <- readCoverage_10x(CoverFile, S.cells=selected_Cells)  

Also, readCoverage_10x function works only for the coverage file of 10x scRNA-seq data. If the user used other datatypes, please use the code below to read the coverage information:
> CoverFile <- './XXX.MT_Coverage.csv'  
> MT_cov <- readCoverage(CoverFile)  

Create mtSNV vaf matrix (variants * cells)
> s.mtSNV_table <- mtSNV_table[mtSNV_table$Cell%in%selected_Cells, ]  
> mtSNV_ma <- MTmutMatrix_refined(MT_variants=s.mtSNV_table, coverage=MTcoverage_inf)  

We focus on the T cells (potential donor cells) and cancer cells (potential receiver cells). For these selected cells, we get the VAF matrix of their mtSNVs (mtSNV_ma).  
Next, we calculate the number of donor cell enriched mtSNVs and the DNA ranks for candidate recievers (mixed cancer cells).
> MTvar_stat_cancerCell <- MERCI_MTvar_cal(mtSNV_ma, MTcoverage_inf, donor_cells=T_cells, mixed_cells=Cancer_cells, min_d=5, min_observeRate= 0.1, Nmut_min=2, pvalue=0.05, qvalue=0.1, OR=2)  

For the parameters of MERCI_MTvar_cal function, such as min_d, min_observeRate, Nmut_min, pvalue, qvalue and OR, please type help (MERCI_MTvar_cal) to check them. The users can change the parameters according to their preferences.  
Load gene expression data (must include the MT genes), Using MERCI LOO pipeline to estiamte the donor and reciever MT contents (decovolution analysis), and RNA ranks for each cancer cell.
> load('./cell_exp.RData')
> library(Matrix)  
> cell_exp <- cell_exp[, selected_Cells]  
> MTfrac_table <- MERCI_LOO_MT_est(cell_exp, reciever_cells=Cancer_cells, donor_cells=T_cells, organism='mouse') ;

MERCI_LOO_MT_est will give the estimated MT constitutes for all potential receiver cells and their RNA ranks. The organism should be noted to be accurate, currently, we only support Human and mouse species.
Significance estimation to test if true-receivers are included based on Rcm values.
> CellN_stat <- CellNumber_test(MTvar_stat_cancerCell, MTfrac_table, Number_R=1000)  

The statistic Rcm value will be returned. If there is Rcm >1 at any cutoff, this means receivers are high likely to be sufficiently included in the input mixed cells. Let’s look at the results:

![Image text]( https://github.com/shyhihihi/MERCI/blob/main/images/image.png)

For rank cutoffs at top rank 20-70%, the Rcm is consistent > 1. The captured number of positive calls is significant and non-random, true receivers are thus considered sufficient in the input cancer cells. We next selected a cutoff to predict the MT receivers. Here, we used the cutoff at top rank 50%, which is a good choice to balance the sensitivity, specificity and precision.
> MTreceiver_pre <- MERCI_ReceiverPre(MTvar_stat_cancerCell, MTfrac_table, top_rank=50)  

Let’s look at the performance of prediction results.

> t.stat <- table(cell_info[Cancer_cells, 'culture_history'], MTreceiver_pre[Cancer_cells, 'prediction'])  
> t.stat  
![Image text]( https://github.com/shyhihihi/MERCI/blob/main/images/t.stat.jpg)

The precision (also called positive predictive value) reached > 76%. Sensitivity and specificity are 89% and 61%. If we selected a more rigorous cutoff (e.g. top 40% or higher), the precision and specificity will increase at the cost of reduced sensitivity.

### MERCI regular
**If there is reference data provided, we recommond to use regular MERCI pipelinee as isllustrated below:**  
Load the independent reference data of pure non-receivers of cancer cells (additional MC cells), including the cell annotation data and gene expression data.
> load(‘./cell_info_nonReceivers.RData’)  
> load(‘./cell_exp_nonReceivers.RData’)  
> ref_noRe_cells <- cell_info_nonReceivers$cell_name  
> selected_Cells <- c(T_cells, Cancer_cells, ref_noRe_cells)  
> c.genes <- intersect(rownames(cell_exp), rownames(cell_exp_nonReceivers)) ;
> cell_exp2 <- cbind(cell_exp[c.genes, ], cell_exp_nonReceivers[c.genes, ]) ;

Read the file of mitochondrial read-coverage based on selected cells, and generate the corresponding vaf matrix for mtSNVs.
> MTcoverage_inf <- readCoverage_10x(CoverFile, S.cells=selected_Cells)  
> s.mtSNV_table <- mtSNV_table[mtSNV_table$Cell%in%selected_Cells, ]  
> mtSNV_ma2 <- MTmutMatrix_refined(MT_variants=s.mtSNV_table, coverage=MTcoverage_inf)  

Calculated the DNA and RNA ranks for the input mixed cells of cancer (mixed_cells), using the data of T cells and new loaded non-receivers as reference.
> MTvar_stat_cancerCell2 <- MERCI_MTvar_cal(mtSNV_ma2, MTcoverage_inf, donor_cells=T_cells, mixed_cells=Cancer_cells, Ref_nonReceivers=ref_noRe_cells, min_d=5, min_observeRate= 0.1, Nmut_min=2, pvalue=0.05, qvalue=0.1, OR=1)  
> MTfrac_table2 <- MERCI_MT_est(cell_exp2, mixed_cells=Cancer_cells, donor_cells=T_cells, Ref_nonReceivers=ref_noRe_cells, organism='mouse')  

Also, perform significance estimation first to obtain the Rcm statistics.
 > CellN_stat2 <- CellNumber_test (MTvar_stat_cancerCell2, MTfrac_table2, Number_R=1000)  
![Image text]( https://github.com/shyhihihi/MERCI/blob/main/images/Rcm_2.jpeg)  

Rcm is consistent > 1 at cutoffs from top rank 20-80%. We next used the same cutoff 50% to predict the mitochondrial receivers.
> MTreceiver_pre2 <- MERCI_ReceiverPre(MTvar_stat_cancerCell2, MTfrac_table2, top_rank=50)  
> t.stat2 <- table(cell_info[Cancer_cells, 'culture_history'], MTreceiver_pre2[Cancer_cells, 'prediction'])  
![Image text]( https://github.com/shyhihihi/MERCI/blob/main/images/t.stat2.jpg)

Compared to the results of prediction without reference data (the results of MERCI LOO pipeline), we can easily find the performance improved with precision = 82%, sensitivity = 72%, and specificity = 90%. But it is enough for using the MERCI LOO pipeline if the user does not have additional reference data.

