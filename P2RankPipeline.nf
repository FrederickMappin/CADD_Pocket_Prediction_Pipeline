#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
/*
========================================================================================
             Pocket Prediciton-NF PIPELINE -  A POCKET PREDICTION PIPELINE
========================================================================================
Pocket Prediciton-NF PIPELINE Started 2024-23-12.
 #### Homepage / Documentation
 https://github.com/FrederickMappin/Pocket_Prediction_Pipeline
 #### Authors
 FrederickMappin<https://github.com/FrederickMappin>
========================================================================================
========================================================================================

Pipeline steps:

    1A. Pocket Prediction using  P2Rank
        P2Rank -- P2Rank is a stand-alone command-line program for fast and accurate prediction of ligand-binding sites from protein structures.
        - Parameters:
            - Predictor: P2Rank
            - Model: Alphafold or Normal
            - Input: PDB files

    1B. Pocket Prediction using  Fpocket
        Fpocket -- Fpocket is a very fast open source protein pocket detection algorithm based on Voronoi tessellation.
        - Parameters:
            - Predictor: Fpocket
            - Input: PDB files

*/



def helpMessage() {
    log.info"""
========================================================================================
                Pocket Prediciton-NF PIPELINE - Help Message
========================================================================================

    Usage:
    The typical command for running the pipeline is as follows:

    nextflow run main.nf -profile <profile> --input '/path/to/input/*_{R1,R2}*.ext' --outdir '/path/to/output/'

    Required arguments:
         -profile                      Configuration profile to use.
         --input                       Directory pattern for input files: "$projectDir/test/*.pdb"

    Save options:
        --outdir                       Specifies where to save the output from the nextflow run.

    """.stripIndent()
}

// Show help message
params.help = false
if (params.help){
    helpMessage()
    exit 0
}

/*
========================================================================================
                        Pipeline Input Parameters
========================================================================================
*/


params.pdb_dir = "$projectDir/test/*.pdb"
params.outdir = "results"
params.predictor = "P2RANK"    // Default predictor
params.model = ""             // Default empty model

log.info """
     Pocket Prediciton-NF PIPELINE    
    ===================================
    Input directory : ${params.pdb_dir}
    Output directory: ${params.outdir}
    Predictor      : ${params.predictor}
    Model          : ${params.model}
    """
    .stripIndent()

// Create channel from input PDB files using tuple
pdb_files_ch = Channel
    .fromPath(params.pdb_dir)
    .map { file -> 
        def name = file.baseName  // gets name without extension
        tuple(name, file)
    }
    .ifEmpty { error "Cannot find any PDB files in ${params.pdb_dir}" }


/*
========================================================================================
             Process 1A: Pocket Prediction using P2Rank
========================================================================================
*/

process P2RANK {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    tuple val(name), path(pdb_file)

    output:
    tuple val(name), path("${name}_p2rank")

    script:
    if (params.predictor == "P2RANK" && params.model == "Alphafold") {
        """
        prank predict -c alphafold ${pdb_file} -o ${name}_p2rank
        """
    } else if (params.predictor == "P2RANK" && params.model != "Alphafold") {
        """
        prank predict -f ${pdb_file} -o ${name}_p2rank
        """
    } else {
        error "Invalid combination of predictor and model"
    }
}


/*
========================================================================================
                    Workflow: Pocket Prediction Pipeline
========================================================================================
*/

workflow {
    P2RANK(pdb_files_ch)
}




/*


VERSION 2 - Pocket Prediction Pipeline
process FPOCKET {
    publishDir "${params.outdir}/fpocket", mode: 'copy'

    input:
    tuple val(name), path(pdb_file)

    output:
    tuple val(name), path("${name}_out")

    script:
    """
    fpocket -f ${pdb_file}
    mkdir ${name}_out
    mv *_out ${name}_out/
    """
}

workflow {
    if (params.predictor == "P2RANK") {
        P2RANK(pdb_files_ch)
    }
    else if (params.predictor == "fpocket") {
        FPOCKET(pdb_files_ch)
    }
    else {
        error "Invalid predictor specified. Use either 'P2RANK' or 'fpocket'"
    }
}

*/