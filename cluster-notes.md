Messer lab cluster tutorial
================

- <a href="#resources" id="toc-resources">Resources</a>
- <a href="#first-things-first-cluster-etiquette"
  id="toc-first-things-first-cluster-etiquette">First things first:
  cluster etiquette</a>
- <a href="#running-slim-on-the-cluster"
  id="toc-running-slim-on-the-cluster">Running SLiM on the cluster</a>
- <a href="#using-jupyter-notebook-on-cluster-for-macs"
  id="toc-using-jupyter-notebook-on-cluster-for-macs">Using Jupyter
  Notebook on cluster (for Macs)</a>
- <a href="#conda-environments" id="toc-conda-environments">Conda
  environments</a>
- <a href="#docker" id="toc-docker">Docker</a>

## Resources

1.  [Detailed cluster tutorial by Nicholas and Isabel (written in
    2021)](https://github.com/therkildsen-lab/user-guide/blob/master/slurm_tutorial/slurm.md)

- This includes notes on how the cluster is organized, how to log into
  the cluster, the different `#SBATCH` headers available, how to set up
  a job array, how to request/use an interactive session with `salloc`,
  and more.

2.  [BioHPC guide on their
    website](https://biohpc.cornell.edu/lab/cbsubscb_SLURM.htm)

3.  [Recordings of past BioHPC
    workshops](https://biohpc.cornell.edu/login_bio.aspx?ReturnURL=/lab/medialist.aspx)

4.  [List of software installed on the cluster & notes on how to use
    them](https://biohpc.cornell.edu/lab/userguide.aspx?a=software)

## First things first: cluster etiquette

``` r
knitr::include_graphics("figures/cluster-partitions.png")
```

<img src="figures/cluster-partitions.png" width="1736" /> Cluster
members find it extremely annoying when one person is taking *all* slots
of a job partition, thus preventing other jobs submitted to that
partition from running. As a good rule of thumb, please make sure that
your job does not use more than 20% of the available slots on your
partition. This percentage can be raised if the cluster is super free
one day (ex: holidays) or if your jobs are extremely quick.

## Running SLiM on the cluster

- Multiple versions of SLiM are available on the cluster. [This
  page](https://biohpc.cornell.edu/lab/userguide.aspx?a=software&i=411#c)
  provides the commands for 5 different versions.

- To vary parameters in SLiM, parse SLiM output, and save your desired
  summary statistics, you can follow Sam’s pipeline:

1.  Edit your SLiM file.

- Copy and paste Sam’s `defineCfgParam` function into your SLiM script
  (see
  [distant_site_pan_TA.slim](slim-example/distant_site_pan_TA.slim)):

``` r
knitr::include_graphics("figures/defineCfgParam.png")
```

<img src="figures/defineCfgParam.png" width="1278" />

- In your SLiM `initialize()` callback, define any parameter that you
  want to vary with `defineCfgParam("PARAMETER_NAME", DEFAULT_VALUE);`.
  For example, if I wanted to vary the germline resistance rate in a
  gene drive model with a default value of 0.9, I’d do
  `defineCfgParam("GERMLINE_RESISTANCE_RATE", 0.9);`.

- Also make sure that you are printing your desired output to the SLiM
  console. For example, if I want to analyze a gene drive’s trajectory
  during the course of the simulation, I’d probably want to print out
  the generation count and the drive allele frequency at the `late()`
  stage of each tick.

2.  Create a Python driver (ex:
    [python-driver.py](slim-example/python-driver.py))

- This script should that use an
  [ArgumentParser](https://docs.python.org/3/library/argparse.html) to
  handle command line arguments, such as the parameters you want to vary
  in SLiM and any other variables that may change, like the number of
  replicates to run or the name of the SLiM file you want to use.
- This script will import functions from Sam’s
  [slimutil.py](slim-example/slimutil.py) script to run SLiM with these
  command line arguments, then parse the output written to the SLiM
  console and print out your desired summary statistics.

3.  Create a text file where each line corresponds to 1 call of your
    Python driver (ex: [params.txt](slim-example/params.txt))

- You can create a text file like this using for-loops in Python or R.
  If I wanted to vary the embryo resistance rate and the germline
  resistance rate on the cluster, for example, I could make a text file
  with these commands using the following Python code (see
  [gen_params.py](slim-example/gen_params.py)):

``` bash
cat slim-example/gen_params.py
```

    ## # pipe this output to a text file you'll use for the cluster run
    ## # ex: python gen_params.py > params.txt
    ## 
    ## from numpy import arange
    ## 
    ## for embryo_res in arange(0.0, 0.25, 0.05):
    ##     for germline_res in arange(0.75, 1.01, 0.05):
    ##         print(f"python python-driver.py -src distant_site_pan_TA.slim -nreps 10 -embryo_res {embryo_res:.3f} -germline_res {germline_res:.3f}")
    ## 

4.  Lastly, create a SLURM script (see
    [slurm-script.sh](slim-example/slurm-script.sh)).

- This should start with headers that specify the memory requirements of
  your job, the job partition you want (which depends on how long you
  think the job will take), a name for your job, a name for your job’s
  output (for standard error messages), and the length of the job array
  (optional).
  - You can use a job array to execute many lines of your text file
    simultaneously. The notation for this is
    `#SBATCH --array=1-<ARRAY_LENGTH>%<MAX_JOBS_AT_A_TIME>`. The
    `ARRAY_LENGTH` corresponds to the number of lines in my text file,
    ie the number of times I’m running the Python driver. The
    `MAX_JOBS_AT_A_TIME` controls how many jobs I can execute
    simultaneously. See **cluster etiquette** — `MAX_JOBS_AT_A_TIME`
    should not exceed more than 20% of the available nodes on the
    partition.
- The SLURM script should next create a temporary working directory for
  this job, navigate into this directory, and copy all files needed to
  execute this job over from your home directory into this new working
  directory.
- Next, add the version of SLiM you want to use to your path.
- Then, you can run the line of your text file located at row
  `SLURM_ARRAY_TASK_ID` using the `sed` command. Pipe the output of your
  Python script to an output file, and then copy this over to your home
  directory.
- Lastly, clean up the working directory by deleting all files.

If you have any questions about this pipeline, talk to Sam or Isabel.

## Using Jupyter Notebook on cluster (for Macs)

To run Jupyter notebook, we’ll use the [jupyter.sh](jupyter.sh) SLURM
script, written by Siddharth.

1.  Potential changes you might want to make to [jupyter.sh](jupyter.sh)
    before running:

- If you would like to run Jupyter lab instead of Jupyter notebook,
  replace ‘notebook’ with ‘lab’ in the SLURM script
- You will only have access to the Jupyter notebook while this SLURM
  script is running. Thus, the job partition should reflect the amount
  of time you want to run the notebook for. See the
  `cluster-partition.png` figure above to decide which partition to
  request, and then change the partition header to this. But note that
  if you plan to keep coming back to this notebook for, say, a week, it
  might make more sense to use the `long7` partition and then `ssh` back
  to this each time you want to use it for the week.
- The default memory requirement is 4G. If you need more or less than
  this, change this header.

2.  Navigate to the directory where files you want to access on your
    notebook are located

3.  Run `sbatch $PATH_TO_DIRECTORY/jupyter.sh`, where
    `PATH_TO_DIRECTORY` is the folder where `jupyter.sh` is stored.

4.  Print (using `cat`) the logfile in the current working directory
    with a name that resembles jupyter_notebook.\*.log

5.  On a different local terminal window, run the ssh line provided in
    the logfile. This will create an `ssh` tunnel that will allow you to
    open the jupyter notebook on your local browser. The command will
    look something like:
    `ssh -L 8877:cbsubscb02:8877 mnc42@cbsubscb02.biohpc.cornell.edu`

- If you’re off-campus, you’ll need to connect to the VPN for this step.

6.  Next, find the link to your Jupyter notebook on your logfile (might
    take a minute or two). It will be after the sentence: ‘copy and
    paste one of these URLs:’

7.  As they said, copy and paste one of the URLs onto your browser, and
    you’re good to go.

Some notes:

- The given `sbatch` file assigns a week or more of resources for the
  notebook. If you don’t plan on using the Jupyter notebook any longer,
  remember to scancel the job (you can view the job number using the
  squeue command and then do `scancel JOB_NUMBER`).

- If you have any questions about this, talk to Meera.

## Conda environments

- conda environments are useful when your job requires multiple packages
  that are not already installed on the cluster. I often use a conda
  environment when my Python driver imports a lot of packages

  - For more on conda environments, see the [conda
    webpage](https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#activating-an-environment)
    or other [online
    resources](https://edcarp.github.io/introduction-to-conda-for-data-scientists/02-working-with-environments/index.html)

- BioHPC recommends installing conda onto your home directory. They
  provide instructions
  [here](https://biohpc.cornell.edu/lab/userguide.aspx?a=software&i=574#c)

- You can create a conda environment by logging into your cluster node
  and then doing `conda create --name environment_name`. You can ensure
  that your environment uses a specific version of Python, like version
  3.9, with `conda create -n myenv python=3.9`

- You can then activate your environment with
  `conda activate environment_name`.

- From this environment, you can install specific versions of packages
  with commands like `conda install scipy=0.15.0 curl=7.26.0`

- You can deactivate your conda environment with `conda deactivate`

- To use your conda environment in a SLURM script, you’d just need to
  activate it before you run your program (or call the Python driver in
  the SLiM example above) and deactivate it afterwards.

ex:

``` r
knitr::include_graphics("figures/conda-env-in-slurm-script.png")
```

<img src="figures/conda-env-in-slurm-script.png" width="810" />

If you have questions about conda environments, talk to Mitch or Isabel

## Docker

- BioHPC is encouraging users to use Docker rather than conda
  environments. Docker is a way to create a virtual machine with all
  your desired packages/programs that you can use any time in the future
  or send to others to use.
- Resources:
  - [Online tutorial](https://docker-curriculum.com/)
  - [BioHPC Docker quick-start
    guide](https://biohpc.cornell.edu/lab/doc/docker_quick_start.pdf)
  - [BioHPC workshop on using
    Docker](https://biohpc.cornell.edu/ww/1/Default.aspx?wid=147)
  - [More BioHPC
    notes](https://biohpc.cornell.edu/lab/userguide.aspx?a=software&i=340#c)
