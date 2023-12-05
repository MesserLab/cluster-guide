from argparse import ArgumentParser
from slimutil import run_slim, configure_slim_command_line

# Make sure slimutil.py is also transferred to this cluster directory

def parse_slim(slim_string):
    """
    Arguments:
        1. slim_string = output printed to the SLiM console
    
    Returns:
        2. suppressed = True if the drive suppressed the population within 100 generations, False if not
    """
    line_split = slim_string.split('\n')
    suppressed = False

    for line in line_split:
        if line.startswith("SUPPRESSION"):
          suppressed = True
        
    return suppressed


def main():
    """
    1. Configure using argparse.
    2. Generate cl string and run SLiM.
    3. Parse the output of SLiM.
    4. Print the results.
    """
    # Get args from arg parser:
    parser = ArgumentParser()
    parser.add_argument('-src', '--src', default="distant_site_pan_TA.slim", type=str,help="SLiM file to be run.")
    parser.add_argument('-nreps', '--nreps', type=int, default=10,help="number of replicates")
    parser.add_argument('-embryo_res', '--EMBRYO_RESISTANCE_RATE', default=0.1, type=float, help="embryo cut rate")
    parser.add_argument('-germline_res', '--GERMLINE_RESISTANCE_RATE', type=float, default=1.0,help="germline cut rate")

    args_dict = vars(parser.parse_args())
    sim_reps = args_dict.pop("nreps")
    embryo_resistance_rate = args_dict["EMBRYO_RESISTANCE_RATE"]
    germline_resistance_rate = args_dict["GERMLINE_RESISTANCE_RATE"]

    # Assemble the command line arguments to use for SLiM:
    clargs = configure_slim_command_line(args_dict)

    # I want to record the fraction of replicates where the drive suppresses the population
    suppression_count = 0
    for i in range(sim_reps):
        slim_result = run_slim(clargs)i
        suppressed = parse_slim(slim_result)
        if suppressed:
          suppression_count += 1
    
    p_suppression = suppression_count/sim_reps
    
    # output: embryo resistance rate, germline resistance rate, fraction of replicates where drive suppressed
    csv_line = f"{embryo_resistance_rate},{germline_resistance_rate},{p_suppression}"
    print(csv_line)

        
if __name__ == "__main__":
    main()
