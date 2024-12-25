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
        P2Rank -- P2Rank is a stand-alone command-line program for fast and accurate prediction of ligand-binding 
        sites from protein structures.
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

    nextflow run P2RankPipeline.nf --inputds /Users/freddymappin/Desktop/alpha/test.ds --outdir /Users/freddymappin/Desktop/test_pdb/ --predictor p2rank
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


params.inputdir = null
params.inputds = null       
params.outdir = "$projectDir/results/"
params.predictor = "P2RANK"    // Default predictor
params.model = ""            // Default empty model

// Print startup message
println """
===================================
Pocket Prediction Pipeline Started
===================================
Input directory : ${params.inputdir}
Output directory: ${params.outdir}
Predictor      : ${params.predictor}
Model          : ${params.model ?: 'default'}
===================================
"""


/*
========================================================================================
             Channel Creation either from input directory or dataset file
========================================================================================
*/


// Create channel from input PDB files with explicit debugging
def dataset_ch
if (params.inputds) {
    dataset_ch = Channel
        .fromPath(params.inputds, checkIfExists: true)
        .view { file -> 
            println "Found dataset file: $file"
            return file
        }
}

// Create a channel for processing individual pdb files (inputdir)
def pdb_files_ch
if (params.inputdir) {
    // If inputdir is provided, create a channel with tuples for each pdb file
    pdb_files_ch = Channel
        .fromPath("${params.inputdir}*.pdb", checkIfExists: true)
        .view { file -> 
            println "Found pdb file: $file"
            return file
        }
        .map { file -> 
            println "Creating tuple for: ${file.baseName}"
            tuple(file.baseName, file) // Create a tuple with the base name and file path
        }
}

if (!dataset_ch && !pdb_files_ch) {
    error "No input directory or dataset provided"
}

/*
========================================================================================
             Process 1A: Pocket Prediction using P2Rank from Directory
========================================================================================
*/

process P2RANK {
    debug true
    tag { name }
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    tuple val(name), path(pdb_file)

    output:
    tuple val(name), path("${name}_p2rank")

    script:
    """
    echo "Processing $name with P2RANK default model"
    ls -l ${pdb_file}
    prank predict -f ${pdb_file} -o ${name}_p2rank
    """
}

/*
========================================================================================
             Process 1B: Pocket Prediction using FPOCKET from Directory
========================================================================================
*/

process FPOCKET {
    debug true
    tag { name }
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    tuple val(name), path(pdb_file)

    output:
    path("*"), emit: fpocket_output  

    script:
    """
    echo "Processing $name with FPOCKET default model"
    ls -l ${pdb_file}
    fpocket -f ${pdb_file}
    """
}

/*
========================================================================================
    Process 1C: Pocket Prediction using P2RANK from Dataset on Alphafold Model
========================================================================================
*/

process P2RANKALPHA {
    debug true
    tag { dataset_file } 
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path dataset_file 

    output:
    path "DS_OUTPUT"

    script:
    """
    echo "Processing dataset file $dataset_file with P2RANK using Alphafold model"
    prank predict -c alphafold ${dataset_file} -o DS_OUTPUT 
    """
}

/*
========================================================================================
    Process 1D: Pocket Prediction using P2RANK from Dataset non-Alphafold Model
========================================================================================
*/

process P2RANKDS {
    debug true
    tag { dataset_file } 
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path dataset_file 

    output:
    path "DS_OUTPUT"

    script:
    """
    echo "Processing dataset file $dataset_file with P2RANK not using an Alphafold model"
    prank predict ${dataset_file} -o DS_OUTPUT 
    """
}

/*
========================================================================================
                        Workflow: Pocket Prediction Pipeline
========================================================================================
*/

// Workflow to run the processes
  workflow {
    // Handle dataset channel
    if (dataset_ch) {
        if (params.predictor.toUpperCase() == "P2RANK" && params.model.toUpperCase() == "ALPHAFOLD") {
            P2RANKALPHA(dataset_ch)
        } else if (params.predictor.toUpperCase() == "P2RANK" && params.model.toUpperCase() != "ALPHAFOLD") {
            P2RANKDS(dataset_ch)
        } else {
            error "Invalid combination of predictor and model for dataset"
        }
    }

    // Handle pdb files channel
    if (pdb_files_ch) {
        if (params.predictor.toUpperCase() == "FPOCKET") {
            FPOCKET(pdb_files_ch)
        } else if (params.predictor.toUpperCase() == "P2RANK") {
            P2RANK(pdb_files_ch)
        } else {
            error "Invalid predictor for pdb files"
        }
    } 
}