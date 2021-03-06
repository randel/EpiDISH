#' @title 
#' Hierarchical EpiDISH (HEpiDISH)
#' 
#' @aliases hepidish
#'  
#' @description 
#' HEpiDISH is an iterative hierarchical procedure of EpiDISH. HEpiDISH uses two 
#' distinct DNAm references, a primary reference for the estimation of several 
#' cell-types fractions, and a separate secondary non-overlapping DNAm reference 
#' for the estimation of underlying subtype fractions of one of the cell-type in 
#' the primary reference.
#' 
#' 
#' @param beta.m
#' A data matrix with rows labeling the molecular features (should use same ID 
#' as in reference matrices) and columns labeling samples (e.g. primary tumour specimens). 
#' Missing value is not allowed and all values should be positive or zero. 
#' In the case of DNA methylation, these are beta-values.
#' 
#' @param ref1.m
#' A matrix of \strong{primary} reference 'centroids', i.e. representative molecular profiles, 
#' for a number of cell subtypes. rows label molecular features (e.g. CpGs,...) 
#' and columns label the cell-type. IDs need to be provided as rownames and 
#' colnames, respectively. Missing value is not allowed, and all values in 
#' this matrix should be positive or zero. For DNAm data, values should be 
#' beta-values.
#' 
#' @param ref2.m
#' Similar to \code{ref1.m}, but now a A matrix of \strong{secondary} reference.
#' For example, \code{ref1.m} contains reference centroids for epithelial cells,
#' fibroblasts and total immune cells. \code{ref2.m} can be subtypes of immune
#' cells, such as B-cells, NK cells, monocytes and etc. 
#' 
#' @param h.CT.idx
#' A index tells which cell-type in \code{ref1.m} is the higher order cell-types 
#' in \code{ref2.m}. For example, \code{ref1.m} contains reference centroids for 
#' epithelial cells, fibroblasts and total immune cells. \code{ref2.m} contains 
#' subtypes of immune cells, the \code{h.CT.idx} should be 3, corresponding to
#' immune cells in \code{ref1.m}.
#' 
#' 
#' @param method
#' Chioce of a reference-based method ('RPC','CBS','CP')
#' 
#' @param maxit
#' Only used in RPC mode, the limit of the number of IWLS iterations
#' 
#' @param nu.v
#' Only used in CBS mode. It is a vector of several candidate nu values. nu is 
#' parameter needed for nu-classification, nu-regression, and 
#' one-classification in svm. The best estimation results among all candidate nu 
#' will be automatically returned.
#' 
#' @param constraint
#' Only used in CP mode, you can choose either of 'inequality' or 'equality' 
#' normalization constraint. The default is 'inequality' (i.e sum of weights 
#' adds to a number less or equal than 1), which was implemented in 
#' Houseman et al (2012).
#' 
#' @return A matrix of the estimated fractions
#' 
#' 
#' @references 
#' Zheng SC, Webster AP, Dong D, Feber A, Graham DG, Sullivan R, Jevons S, Lovat LB, 
#' Beck S, Widschwendter M, Teschendorff AE
#' \emph{A novel cell-type deconvolution algorithm reveals substantial contamination by immune cells in saliva, buccal and cervix.}
#' Epigenomics (2018) 10: 925-940.
#' doi:\href{https://doi.org/10.2217/epi-2018-0037}{
#' 10.2217/epi-2018-0037}.
#' 
#' Teschendorff AE, Breeze CE, Zheng SC, Beck S. 
#' \emph{A comparison of reference-based algorithms for correcting cell-type 
#' heterogeneity in Epigenome-Wide Association Studies.}
#' BMC Bioinformatics (2017) 18: 105.
#' doi:\href{https://doi.org/10.1186/s12859-017-1511-5}{
#' 10.1186/s12859-017-1511-5}.
#' 
#' Houseman EA, Accomando WP, Koestler DC, Christensen BC, Marsit CJ, 
#' Nelson HH, Wiencke JK, Kelsey KT. 
#' \emph{DNA methylation arrays as surrogate measures of cell mixture 
#' distribution.} 
#' BMC Bioinformatics (2012) 13: 86.
#' doi:\href{https://doi.org/10.1186/1471-2105-13-86}{10.1186/1471-2105-13-86}.
#' 
#' Newman AM, Liu CL, Green MR, Gentles AJ, Feng W, Xu Y, Hoang CD, Diehn M, 
#' Alizadeh AA. 
#' \emph{Robust enumeration of cell subsets from tissue expression profiles.}
#' Nat Methods (2015) 12: 453-457.
#' doi:\href{https://doi.org/10.1038/nmeth.3337}{10.1038/nmeth.3337}.
#' 
#' @examples 
#' data(centEpiFibIC.m)
#' data(centBloodSub.m)
#' data(DummyBeta.m)
#' frac.m <- hepidish(beta.m = DummyBeta.m, ref1.m = centEpiFibIC.m, 
#' ref2.m = centBloodSub.m, h.CT.idx = 3, method = 'RPC')
#' 
#' 
#' @export
#'     

hepidish <- function(beta.m, ref1.m, ref2.m, h.CT.idx, method = c("RPC", "CBS", "CP"), 
    maxit = 50, nu.v = c(0.25, 0.5, 0.75), constraint = c("inequality", "equality")) {
    method <- match.arg(method)
    constraint <- match.arg(constraint)
    if (!method %in% c("RPC", "CBS", "CP")) 
        stop("Input a valid method!")
    if (method == "RPC") {
        frac1.m <- DoRPC(beta.m, ref1.m, maxit)$estF
        frac2.m <- DoRPC(beta.m, ref2.m, maxit)$estF
        frac.m <- cbind(frac1.m[, -h.CT.idx, drop = FALSE], frac1.m[, h.CT.idx] * frac2.m)
    } else if (method == "CBS") {
        frac1.m <- DoCBS(beta.m, ref1.m, nu.v)$estF
        frac2.m <- DoCBS(beta.m, ref2.m, nu.v)$estF
        frac.m <- cbind(frac1.m[, -h.CT.idx, drop = FALSE], frac1.m[, h.CT.idx] * frac2.m)
    } else if (method == "CP") {
        if (!constraint %in% c("inequality", "equality")) {
            # make sure constraint must be inequality or equality
            stop("constraint must be inequality or equality when using CP!")
        } else {
            frac1.m <- DoCP(beta.m, ref1.m, constraint)$estF
            frac2.m <- DoCP(beta.m, ref2.m, constraint)$estF
            frac.m <- cbind(frac1.m[, -h.CT.idx, drop = FALSE], frac1.m[, h.CT.idx] * frac2.m)
        }
    }
    return(frac.m)
}





