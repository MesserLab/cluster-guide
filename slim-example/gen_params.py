# pipe this output to a text file you'll use for the cluster run
# ex: python gen_params.py > params.txt

from numpy import arange

for embryo_res in arange(0.0, 0.25, 0.05):
    for germline_res in arange(0.75, 1.01, 0.05):
        print(f"python python-driver.py -src distant_site_pan_TA.slim -nreps 10 -embryo_res {embryo_res:.3f} -germline_res {germline_res:.3f}")

