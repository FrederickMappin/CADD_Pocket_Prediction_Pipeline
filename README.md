# NF-Pocket Prediction

nf-pocket prediction is a workflow designed to allow robust usage of P2rank and fpocket for protein pocket predictions. The fpocket suite of programs is a very fast open source protein pocket detection algorithm based on Voronoi tessellation. P2Rank is a stand-alone command-line program for fast and accurate prediction of ligand-binding sites from protein structures. It achieves high prediction success rates without relying on external software for computation of complex features or on a database of known protein-ligand templates.
The pipeline is built using Nextflow, a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker containers making installation trivial and results highly reproducible. 

## Dependencies 
Nf-pocket prediction require running in an environment containing the listed programs. Please go to source for installation instructions:
- Nextflow
- Docker
- streamlit (optional to run command generator GUI)  

## Usage 


nf-Pocket Prediction has four different modes that differ based on input type , protein model, and pocket predictor. 

```
# Run P2Rank Predictor on a Directory of PDB files 

nextflow run P2RankPipeline.nf --inputdir /path/to/your/directory/ --outdir /path/to/your/directory/ --predictor P2Rank 

# Run FPocket Predictor on a Directory of PDB files 

 nextflow run P2RankPipeline.nf --inputdir /path/to/your/directory/ --outdir /path/to/your/directory/ --predictor fpocket 

# Run P2Rank Predictor on a Dataset of Alphafold PDB files (Recommended for Alphafold models)

 nextflow run P2RankPipeline.nf --inputds /path/to/your/directory/file.ds --outdir /path/to/your/directory/ --predictor P2Rank --model Alphafold

# Run P2Rank Predictor on a Dataset of non-Alphafold PDB files 

nextflow run P2RankPipeline.nf --inputds /path/to/your/directory/file.ds --outdir /path/to/your/directory/ --predictor P2Rank

Required arguments:

    --inputdir or inputds                       Directory for input PDB files or dataset file
    --predictor                                 Pocket predictor to use (P2Rank or Fpocket)

    Optional arguments:
    --model                                     Model to use for P2Rank (Alphafold or Normal)

    Save options:
    --outdir                       Specifies where to save the output from the nextflow run
```

## Command Generator app

 ```
streamlit run command_gen.py
```
This is a pop up a command generator app that can be used to write the command to be copied and run in CLI.

<img width="333" alt="Screenshot 2025-01-03 at 5 37 49 PM" src="https://github.com/user-attachments/assets/f347020e-030e-41fd-b47c-3c550b9daafe" />




## Testing and set-up 

Dataset files "file.ds" require that the absolute path be used, an example file can be found in the test folder:

```
# no header => dataset contains list of protein files

/workspaces/CADD_Pocket_Prediction_Pipeline/test/AAEL000614.pdb
/workspaces/CADD_Pocket_Prediction_Pipeline/test/AAEL000616.pdb
/workspaces/CADD_Pocket_Prediction_Pipeline/test/AAEL000628.pdb
/workspaces/CADD_Pocket_Prediction_Pipeline/test/AAEL001221.pdb

```

nf-Pocket Prediction requires little set-up assuming you have nextflow and Docker probably installed. nf-Pocket Prediction was tested locally, gitpod, and github's codespace. Required Docker containers are automatically pulled from repo for use and indicated in the config file, dockerfile used to make image also inculded but likely dont need to build. 

If setting up for the first time it is suggested to run testing using test data found in the test folder.

```
# Run P2Rank Predictor on a Directory of PDB files 

nextflow run P2RankPipeline.nf --inputdir ./test/ --outdir ./results/ --predictor P2Rank 

# Run FPocket Predictor on a Directory of PDB files 

 nextflow run P2RankPipeline.nf --inputdir ./test/ --outdir ./results/ --predictor fpocket

Prepare Dataset test.ds file by adding absolute to the name!! Ex. /Users/Desktop/files/AAEL000614.pdb

# Run P2Rank Predictor on a Dataset of Alphafold PDB files (Recommended for Alphafold models)

 nextflow run P2RankPipeline.nf --inputds ./test/test.ds --outdir ./results/ --predictor P2Rank --model Alphafold

# Run P2Rank Predictor on a Dataset of non-Alphafold PDB files 

nextflow run P2RankPipeline.nf --inputds ./test/test.ds --outdir ./results/ --predictor P2Rank
```
