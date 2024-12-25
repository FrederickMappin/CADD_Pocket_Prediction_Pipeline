#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
========================================================================================
             Pocket Prediction Pipeline
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


process P2RANK {
    debug true
    tag { name }
    publishDir "${params.outdir}", mode: 'copy'
    
    input:
    tuple val(name), path(pdb_file)

    output:
    tuple val(name), path("${name}_p2rank")

    script:
    println "Starting to process: $name with file $pdb_file"
    
    if (params.predictor.toUpperCase() == "P2RANK" && params.model.toUpperCase() != "ALPHAFOLD") {
        """
        echo "Processing $name with P2RANK default model"
        ls -l ${pdb_file}
        prank predict -f ${pdb_file} -o ${name}_p2rank
        """
    } else {
        error "Invalid combination of predictor and model"
    }
}

// Process for handling dataset file (single file from dataset_ch)
process P2RANKALPHA {
    debug true
    tag { dataset_file } 
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path dataset_file 

    output:
    path "DS_OUTPUT"

    script:
    println "Starting to process dataset: $dataset_file"
     if (params.predictor.toUpperCase() == "P2RANK" && params.model.toUpperCase() == "ALPHAFOLD") {
    """
    echo "Processing dataset file $dataset_file with P2RANK using Alphafold model"
    prank predict -c alphafold ${dataset_file} -o DS_OUTPUT 
    """
    } else {
        error "Invalid combination of predictor and model"
    }
}

 // Workflow to run the processes
workflow {
    if (dataset_ch) {
        P2RANKALPHA(dataset_ch)
    }
    if (pdb_files_ch) {
        P2RANK(pdb_files_ch)
    }
}


