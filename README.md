This is a comprehensive `README.md` file tailored specifically to your script. It explains the workflow, the requirements, and how to use the automation tool.

You can copy and paste the content below into a new file named `README.md` in your **GROMACS_RUN** repository.


# GROMACS_RUN: Automated Molecular Dynamics Pipeline

This repository contains a Bash script (`gmx_auto.sh`) designed to automate the standard GROMACS molecular dynamics (MD) workflow. It handles everything from initial structure processing (including CIF to PDB conversion) to production MD and basic trajectory analysis.

# Features
- **Automatic Format Conversion:** Converts `.cif` files to `.pdb` using Open Babel.
- **Pre-processing:** Automatically removes water molecules (HOH) and cleans the PDB file.
- **Complete MD Workflow:** Automates `pdb2gmx`, box definition, solvation, ion addition, energy minimization, and equilibration (NVT/NPT).
- **HPC Optimized:** Configured with specific threading flags for high-performance computing environments.
- **Built-in Analysis:** Generates RMSD, RMSF, Radius of Gyration (Rg), and Covariance data automatically after the run.

# Prerequisites

Before running the script, ensure the following software is installed and accessible in your environment:
1.  **GROMACS:** The script uses the `gmx` command.
2.  **Open Babel:** Required for converting `.cif` files.
3.  **MDP Files:** You must have a directory containing the following parameter files:
    - `ions.mdp`, `em.mdp`, `nvt.mdp`, `npt.mdp`, `md.mdp`

# Configuration

In the `gmx_auto.sh` script, check the **CONFIGURATION** section to ensure the paths match your system:

* `MDP_DIR`: The absolute path to your folder containing the `.mdp` files.
* `FF_INDEX`: Set to `8` (AMBER99SB-ILDN) by default.
* `RUN_FLAGS`: Current settings use `-ntmpi 2 -ntomp 14`. Adjust these based on your CPU/GPU availability.

# Usage

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Ritam1504/GROMACS_RUN.git
    cd GROMACS_RUN
    ```

2.  **Make the script executable:**
    ```bash
    chmod +x gmx_auto.sh
    ```

3.  **Run the simulation:**
    Provide the full path to your protein structure file (PDB or CIF) as an argument:
    ```bash
    ./gmx_auto.sh /path/to/your/protein.pdb
    ```

# Workflow Steps

The script executes the following 15 steps:
1.  **Conversion:** CIF to PDB (if necessary).
2.  **Cleaning:** Removal of crystallographic water.
3.  **System Preparation:** `pdb2gmx` (AMBER99SB-ILDN, TIP3P).
4.  **Box Definition:** Cubic box with 1.0 nm solvent shell.
5.  **Solvation:** Adding water molecules.
6.  **Ions:** Neutralizing the system with NA/CL.
7.  **Energy Minimization:** Reaching the local energy minimum.
8.  **NVT Equilibration:** Constant Number of particles, Volume, and Temperature.
9.  **NPT Equilibration:** Constant Number of particles, Pressure, and Temperature.
10. **Production MD:** Running the main trajectory.
11. **Analysis:** Generating `.xvg` files for RMSD, RMSF, Gyration, and Covariance.

# Output Files

All output files, including trajectories (`.xtc`), topologies (`.top`), and analysis graphs (`.xvg`), are saved directly in the directory where the input protein file is located.

# License
This project is open-source. Please attribute the author if you use these scripts in your research.
