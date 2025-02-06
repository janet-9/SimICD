# Script to extract the Phie recordings from the ICD leads during a simulation - Dumps the ascii file into the simulation file in which the phie file is stored
# TO-DO: Find a way to stop the extra file being generated when running this script! 
import os
from datetime import date
import glob
from carputils import tools
from carputils import ep
from carputils import settings 

EXAMPLE_DESCRIPTIVE_NAME = 'Phie Extractor'
EXAMPLE_AUTHOR = 'Hannah Lydon <k23086865@kcl.ac.uk>'
EXAMPLE_DIR = os.path.dirname(__file__)
CALLER_DIR = os.getcwd()
GUIinclude = False

def parser():
    # Generate the standard command line parser
    parser = tools.standard_parser()
    group  = parser.add_argument_group('experiment specific options')

    # Add experiment arguments - the simulation folder to look in and the name to call the extracted ascii of the phie traces
    group.add_argument('--sim_folder',
                       type=str, default=EXAMPLE_DIR,
                       help='Simulation folder to look in (default is %(default)s, the current file you are working in.)')
    group.add_argument('--phie_name',
                       type=str, default='phie_icd',
                       help='Name of extracted phie traces (default is %(default)s)')

    return parser

@tools.carpexample(parser)#, jobID)
def run(args, job):

    # Run igbextract
    cmd = [settings.execs.igbextract,
               '-o', 'asciiTm',
               '-O', '{}/{}'.format(args.sim_folder,args.phie_name),
               os.path.join(args.sim_folder, 'phie.igb')]
    job.bash(cmd)

if __name__ == '__main__':
    run()
