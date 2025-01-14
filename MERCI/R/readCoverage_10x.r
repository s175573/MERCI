#' Read in the mitochondrial read coverage inforamtion
#'
#' This function read in MT coverage inforamtion (*.Coverage_Cell.csv) generated by MERCI-mtSNP, only works for 10x_scRNA-seq data type.
#' @param CoverFile The path to .Coverage_Cell.csv file generated by MERCI-mtSNP.
#' @param S.cells a list of cells, the MT coverage of only these selected cells will be returned. if not provided then all cells will be considered, default=NULL.
#' @return a boxplot showing the MT coverage distribution across cells, a data.frame for MT coverage inforamtion
#' @export
#' @examples readCoverage_10x(CoverFile='./X.Coverage_Cell.csv', S.cells=NULL)

readCoverage_10x <- function(CoverFile, S.cells=NULL)
{
	MT_coverage <- read.csv(CoverFile, row.names=1) ;
	colnames(MT_coverage) <- gsub("\\.",  "-", colnames(MT_coverage)) ;

	if(is.null(S.cells))
	S.cells <- colnames(MT_coverage) ;
	coverage_plot(S.cells, MT_coverage) ;
	MT_coverage <- MT_coverage[, S.cells] ;
	return(MT_coverage) ;
}

