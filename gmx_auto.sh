#!/bin/bash

# Exit on any error
set -e

# --- 1. CONFIGURATION ---
# Absolute path to your MDP files
MDP_DIR="/data/sata_data/home/analabha_t1/GROMACS_mdp_files"
FF_INDEX="8" # AMBER99SB-ILDN
RUN_FLAGS="-ntmpi 2 -ntomp 14 -pin on -nb cpu -pme cpu"

if [ -z "$1" ]; then
    echo "Error: No input file provided."
    echo "Usage: gmx_auto.sh /full/path/to/protein.pdb"
    exit 1
fi

# --- 2. DYNAMIC PATH HANDLING ---
# Get the full absolute path of the input file
ABS_INPUT_PATH=$(readlink -f "$1")
# Identify the directory where the input file lives
TARGET_DIR=$(dirname "$ABS_INPUT_PATH")
# Get just the filename (e.g., HRAS.cif)
FILE_NAME=$(basename "$ABS_INPUT_PATH")
# Get the base name without extension (e.g., HRAS)
BASE="${FILE_NAME%.*}"
EXTENSION="${FILE_NAME##*.}"

# --- 3. SWITCH TO TARGET FOLDER ---
# This ensures all generated files stay with the PDB
cd "$TARGET_DIR"
echo "Running simulation in: $TARGET_DIR"

# --- 4. PRE-PROCESSING ---
if [ "$EXTENSION" == "cif" ]; then
    echo "Step 1: Converting CIF to PDB..."
    obabel -icif "$FILE_NAME" -opdb -O "${BASE}.pdb"
    PROTEIN_PDB="${BASE}.pdb"
else
    echo "Step 1: PDB detected, skipping conversion."
    PROTEIN_PDB="$FILE_NAME"
fi

echo "Step 2: Cleaning PDB..."
grep -v HOH "$PROTEIN_PDB" > "${BASE}_clean.pdb"

# --- 5. GROMACS PIPELINE ---
echo "Step 3: pdb2gmx"
echo "$FF_INDEX" | gmx pdb2gmx -f "${BASE}_clean.pdb" -o processed.gro -water tip3p -ignh

echo "Step 4: Box Definition"
gmx editconf -f processed.gro -o newbox.gro -c -d 1.0 -bt cubic

echo "Step 5: Solvation"
gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p topol.top

echo "Step 7-8: Ions"
gmx grompp -f "$MDP_DIR/ions.mdp" -c solv.gro -p topol.top -o ions.tpr -maxwarn 1
echo "13" | gmx genion -s ions.tpr -o solv_ions.gro -p topol.top -pname NA -nname CL -neutral

echo "Step 10: Energy Minimization"
gmx grompp -f "$MDP_DIR/em.mdp" -c solv_ions.gro -p topol.top -o em.tpr
gmx mdrun -v -deffnm em $RUN_FLAGS

echo "Step 12: NVT"
gmx grompp -f "$MDP_DIR/nvt.mdp" -c em.gro -r em.gro -p topol.top -o nvt.tpr -maxwarn 1
gmx mdrun -deffnm nvt $RUN_FLAGS

echo "Step 13: NPT"
gmx grompp -f "$MDP_DIR/npt.mdp" -c nvt.gro -r nvt.gro -p topol.top -o npt.tpr -maxwarn 1
gmx mdrun -deffnm npt $RUN_FLAGS

echo "Step 14: Production MD"
gmx grompp -f "$MDP_DIR/md.mdp" -c npt.gro -p topol.top -o md.tpr -maxwarn 1
gmx mdrun -deffnm md $RUN_FLAGS

# --- 6. ANALYSIS ---
echo "Step 15: Analysis"
echo "1 1" | gmx rms -s md.tpr -f md.xtc -o rmsd.xvg -tu ns
echo "1"   | gmx rmsf -s md.tpr -f md.xtc -o rmsf.xvg -res
echo "1"   | gmx gyrate -s md.tpr -f md.xtc -o gyrate.xvg
echo "1"   | gmx chi -s md.tpr -f md.xtc -o chi.xvg -all
echo "1 1" | gmx covar -s md.tpr -f md.xtc -o eigenvalues.xvg -v eigenvectors.trr

echo "All files have been saved to: $TARGET_DIR"


