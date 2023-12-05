#!/bin/bash
#SBATCH --partition regular,long7,long30
#SBATCH --nodes 1
#SBATCH --ntasks-per-node 1
#SBATCH --mem-per-cpu 4G
#SBATCH --job-name jupyter-notebook
#SBATCH --output jupyter_notebook.%A.log

# get tunneling info
XDG_RUNTIME_DIR=""
port=$(shuf -i8000-9999 -n1)
node=$(hostname -s)
user=$(whoami)
cluster=$(hostname -f)

date

/programs/bin/labutils/mount_server cbsubscb18 /storage

# print tunneling instructions jupyter-log
echo -e "
MacOS or linux terminal command to create your ssh tunnel:
ssh -L ${port}:${node}:${port} ${user}@${cluster}

For more info and how to connect from windows,
   see research.computing.yale.edu/jupyter-nb
Here is the MobaXterm info:

Forwarded port:same as remote port
Remote server: ${node}
Remote port: ${port}
SSH server: ${cluster}.biohpc.cornell.edu
SSH login: $user
SSH port: 22

Use a Browser on your local machine to go to:
localhost:${port}  (prefix w/ https:// if using password)
"


source ~/.bashrc
module load python/3.10.6-r9

#python -m ipykernel install --user --name=sciComp

# DON'T USE ADDRESS BELOW.
# DO USE TOKEN BELOW
jupyter notebook  --no-browser --port=${port} --ip=${node}