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

    1A. Pocket Prediction using P2Rank on a directory of PDB files
        - inputdir: Directory containing PDB files
        - predictor: P2Rank
        - model: Default model
        
    1B. Pocket Prediction using  Fpocket ob a directory of PDB files
        - inputdir: Directory containing PDB files
        - predictor: Fpocket
        - model: Default model

    1C. Pocket Prediction using P2Rank on a dataset of Alphafold PDB files
        - inputds: Dataset file containing Alphafold PDB files
        - predictor: P2Rank
        - model: Alphafold

    1D. Pocket Prediction using P2Rank on a dataset of non-Alphafold PDB files
        - inputds: Dataset file containing non-Alphafold PDB files
        - predictor: P2Rank
        - model: Default model

*/

def helpMessage() {
    log.info"""
========================================================================================
                Pocket Prediciton-NF PIPELINE - Help Message
========================================================================================

    Usage:
The typical command for running the pipeline is as follows:
nf-Pocket Prediction has four different mode that difer based on input type , protein model, and pocket predictor.
========================================================================================
# Run P2Rank Predictor on a Directory of PDB files 

    ```nextflow run P2RankPipeline.nf --inputdir /path/to/your/directory/ --outdir /path/to/your/directory/ --predictor P2Rank ```

# Run FPocket Predictor on a Directory of PDB files 

    ```nextflow run P2RankPipeline.nf --inputdir /path/to/your/directory/ --outdir /path/to/your/directory/ --predictor fpocket ```

# Run P2Rank Predictor on a Dataset of Alphafold PDB files (Recommended for Alphafold models)

    ```nextflow run P2RankPipeline.nf --inputds /path/to/your/directory/file.ds --outdir /path/to/your/directory/ --predictor P2Rank --model Alphafold```

# Run P2Rank Predictor on a Dataset of non-Alphafold PDB files 

    ```nextflow run P2RankPipeline.nf --inputds /path/to/your/directory/file.ds --outdir /path/to/your/directory/ --predictor P2Rank```

Required arguments:

    --inputdir or inputds                       Directory for input PDB files or dataset file
    --predictor                                 Pocket predictor to use (P2Rank or Fpocket)

    Optional arguments:
    --model                                     Model to use for P2Rank (Alphafold or Normal)

    Save options:
    --outdir                       Specifies where to save the output from the nextflow run

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