import streamlit as st
import os

def main():
    st.title("Pocket Prediction Pipeline Command Generator")

    # Input for input directory
    input_dir = st.text_input('input_dir -Input Directory (path to input PDB files)', value='')

    # Input for dataset file
    input_ds = st.text_input('input_ds - Dataset File (path to dataset file)', value='')

    # Input for output directory
    output_dir = st.text_input('output_dir - Output Directory (path to save Pocket predictions)', value='')

    # Input for predictor
    predictor = st.selectbox('predictor', ['P2Rank', 'Fpocket'])

    # Conditional input for model (optional)
    model = ''
    if input_ds and predictor == 'P2Rank':
        model = st.selectbox('model (optional)', ['', 'Alphafold'])

    # Validation check
    if input_dir and input_ds:
        st.error("Please provide either an Input Directory or a Dataset File, but not both.")
        return
    if input_ds and predictor == 'Fpocket':
        st.error("Dataset File and Fpocket is not a valid combination.")
        return

    # Construct the command
    command = ""
    if input_dir:
        command = f"nextflow run P2RankPipeline.nf --inputdir {input_dir} --outdir {output_dir} --predictor {predictor}"
        if model:
            command += f" --model {model}"
    elif input_ds:
        command = f"nextflow run P2RankPipeline.nf --inputds {input_ds} --outdir {output_dir} --predictor {predictor}"
        if model:
            command += f" --model {model}"

    st.write(f"Generated Command: `{command}`")

    # RUN button
    if st.button("RUN"):
        # Execute the command
        os.system(command)
        st.success('Command executed!')

if __name__ == "__main__":
    main()