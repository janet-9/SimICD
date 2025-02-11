#Basic Ventricular Stimulation script: Options to pulse for the desired strength, stim duration, no. pulses, bcl, start times for pulses, cell model and options to checkpoint. You can also choose the output resolution to save on simulation time.
import os

EXAMPLE_DESCRIPTIVE_NAME = 'Example of NSR'
EXAMPLE_DIR = os.path.dirname(__file__)
CALLER_DIR = os.getcwd()
GUIinclude = False

from datetime import date
from carputils import tools
from carputils import ep


def parser():
    # Generate the standard command line parser
    parser = tools.standard_parser()
    group  = parser.add_argument_group('experiment specific options')

    # Add experiment arguments
  
    #Mesh specific arguments 
    group.add_argument('--mesh',
                       type = str, default = 'ventricles_coarser_RV_infarct',
                      help = 'Simulation mesh (default is %(default)s)' )
    group.add_argument('--conmul',
                       type = float, default = 0.85,
                       help = 'Multiplication factor for conductivityin the isthmus (default is %(default)s)')
    group.add_argument('--input_state',
                       type = str, default = "2_RV_reentrant_bottom_350.roe",
                       help = 'Checkpointed State at which to start the ATP therapy from, default is %(default)s')
    group.add_argument('--model',
                        type = str,
                        default = "tenTusscherPanfilov", 
                        help='ionic model (default is %(default)s)')

   #Length of full simulation run-time - remember the time stamp of the input state! 
    group.add_argument('--tend',
                       type = float, default = 30000,
                       help = 'Duration of simulation (default is %(default)s) ms')
    
    #NSR arguments 
    group.add_argument('--pls',
                       type = float, default = 38,
                       help = 'Number of pulses (default is %(default)s)')
    group.add_argument('--bcl',
                        type = float, default = 800,
                        help = 'BCL pulses (default is %(default)s ms, 75bpm )')
    group.add_argument('--strength',
                        type = float, default = 450,
                        help = 'Strength for the stimulation (default is %(default)s muA)')
    group.add_argument('--duration',
                        type = float, default = 4,
                        help = 'Duration for the stimulation (default is %(default)s  ms)')
    group.add_argument('--start',
                       type = float, default = 0,
                       help = 'Start time of whole heart stimulation (default is %(default)s ms)')
    
    # Output arguments, resolution of the output files and checn checkpoints are generated 
    group.add_argument('--output_res',
                       type = float, default = 1,
                       help = 'Resolution of output for .igb files (default is %(default)s ms)')
    group.add_argument('--check',
                       type = float, default = 1000,
                       help = 'Time interval for saving the state of the simulation (default is %(default)s ms, 1 second )')
    return parser

def jobID(args):
    today = date.today()
    ID = '{}_{}_INPUT_{}_conmul_{:.2f}'.format(today.isoformat(), args.mesh, args.input_state, args.conmul)
    return ID

@tools.carpexample(parser, jobID)
def run(args, job):

    # Generate general command linetete
    cmd = tools.carp_cmd()

    # Set output directory
    cmd += ['-simID', job.ID]

    # Add some example-specific command line options
    cmd += ['-meshname', args.mesh,
             '-start_statef', args.input_state,
            '-tend', args.tend,
            '-gridout_i', 3,
            #'-gridout_e', 3
    ]
    
    #Define phie points 
    cmd += [
             '-phie_rec_ptf', 'electrodesICD',
            ]
    
    #Adding commands for mesh properties

    #Define the physics regions
    cmd += ['-num_phys_regions', 2,
            '-phys_region[0].name', 'intracellular',
            '-phys_region[0].ptype', 0,
            '-phys_region[1].name', 'extracellular',
            '-phys_region[1].ptype', 1
            ]
    #Define the ionic model to use
    cmd += ['-num_imp_regions',          1,
            '-imp_region[0].im',         args.model,
            ]
    #Define the conductivities
    cmd += ['-num_gregions',			3,
    		'-gregion[0].name', 		"myocardium",
                '-gregion[0].num_IDs', 4,
                '-gregion[0].ID[0]', 21,
                '-gregion[0].ID[1]', 212,
                '-gregion[0].ID[2]', 22,
                '-gregion[0].ID[3]', 222,
    		# mondomain conductivites will be calculated as half of the harmonic mean of intracellular
    		# and extracellular conductivities
    		'-gregion[0].g_el', 		3.3558,	# extracellular conductivity in longitudinal direction
    		'-gregion[0].g_et', 		1.253,	# extracellular conductivity in transverse direction
    		'-gregion[0].g_en', 		0.8295,	# extracellular conductivity in sheet direction
    		'-gregion[0].g_il', 		0.9324,	# intracellular conductivity in longitudinal direction
    		'-gregion[0].g_it', 		0.35,	# intracellular conductivity in transverse direction
    		'-gregion[0].g_in', 		0.2345,	# intracellular conductivity in sheet direction
    		'-gregion[0].g_mult',		1.0, # scale all conducitivites by a factor (to alter conduction velocity)   

                '-gregion[1].name', 		"Scar",
                '-gregion[1].num_IDs', 1,
                '-gregion[1].ID[0]', 300,
    		# mondomain conductivites will be calculated as half of the harmonic mean of intracellular
    		# and extracellular conductivities
    		'-gregion[1].g_el', 		0.001,	# extracellular conductivity in longitudinal direction
    		'-gregion[1].g_et', 		0.001,	# extracellular conductivity in transverse direction
    		'-gregion[1].g_en', 		0.001,	# extracellular conductivity in sheet direction
    		'-gregion[1].g_il', 		0.001,	# intracellular conductivity in longitudinal direction
    		'-gregion[1].g_it', 		0.001,	# intracellular conductivity in transverse direction
    		'-gregion[1].g_in', 		0.001,	# intracellular conductivity in sheet direction
    		'-gregion[1].g_mult',		1.0, # scale all conducitivites by a factor (to alter conduction velocity)

                '-gregion[2].name', 		"isthmus",
                '-gregion[2].num_IDs', 1,
                '-gregion[2].ID[0]', 400,
           
    		# mondomain conductivites will be calculated as half of the harmonic mean of intracellular
    		# and extracellular conductivities
    		'-gregion[2].g_el', 		3.3558,	# extracellular conductivity in longitudinal direction
    		'-gregion[2].g_et', 		1.2530,	# extracellular conductivity in transverse direction
    		'-gregion[2].g_en', 		0.8295,	# extracellular conductivity in sheet direction
    		'-gregion[2].g_il', 		0.9324,	# intracellular conductivity in longitudinal direction
    		'-gregion[2].g_it', 		0.3500,	# intracellular conductivity in transverse direction
    		'-gregion[2].g_in', 		0.2345,	# intracellular conductivity in sheet direction
    		'-gregion[2].g_mult',		args.conmul, #scale all conducitivites by a factor (to alter conduction velocity) 

    ]
    #Define the stimulus
    cmd += ['-num_stim',  5,
            
           '-stimulus[0].vtx_fcn', 1,
           '-stimulus[0].vtx_file', "LV_af.vtx",
           '-stimulus[0].stimtype',  0,
           '-stimulus[0].strength', args.strength,
           '-stimulus[0].duration', args.duration,
           '-stimulus[0].start', args.start,
           '-stimulus[0].npls',  args.tend/args.bcl,
           '-stimulus[0].bcl',  args.bcl,

           '-stimulus[1].vtx_fcn', 1,
           '-stimulus[1].vtx_file', "LV_pf.vtx",
           '-stimulus[1].stimtype',  0,
           '-stimulus[1].strength', args.strength,
           '-stimulus[1].duration', args.duration,
           '-stimulus[1].start', args.start,
           '-stimulus[1].npls',  args.tend/args.bcl,
           '-stimulus[1].bcl',  args.bcl,

           '-stimulus[2].vtx_fcn', 1,
           '-stimulus[2].vtx_file', "LV_sf.vtx",
           '-stimulus[2].stimtype',  0,
           '-stimulus[2].strength', args.strength,
           '-stimulus[2].duration', args.duration,
           '-stimulus[2].start', args.start,
           '-stimulus[2].npls',  args.tend/args.bcl,
           '-stimulus[2].bcl',  args.bcl,

           '-stimulus[3].vtx_fcn', 1,
           '-stimulus[3].vtx_file', "RV_mod.vtx",
           '-stimulus[3].stimtype',  0,
           '-stimulus[3].strength', args.strength,
           '-stimulus[3].duration', args.duration,
           '-stimulus[3].start', args.start,
           '-stimulus[3].npls',  args.tend/args.bcl,
           '-stimulus[3].bcl',  args.bcl,

           '-stimulus[4].vtx_fcn', 1,
           '-stimulus[4].vtx_file', "RV_sf.vtx",
           '-stimulus[4].stimtype',  0,
           '-stimulus[4].strength', args.strength*0.5,
           '-stimulus[4].duration', args.duration,
           '-stimulus[4].start', args.start,
           '-stimulus[4].npls',  args.tend/args.bcl,
           '-stimulus[4].bcl',  args.bcl
            
    ]

      #Define outputs and postprocesses
    cmd += ['-spacedt', args.output_res,
            '-timedt', 1.0,
            ]
    
    cmd += ['-chkpt_start', 0,
            '-chkpt_intv',  args.check,
            '-chkpt_stop', args.tend
            ]
#Define phie points 
    
    cmd += [
             '-post_processing_opts', 1, 
             '-phie_rec_ptf', 'electrodesICD',
             '-phie_recovery_file', 'phie',
             '-phie_rec_meth', 1,
             #'-compute_APD', 1
          
               ]


    # Run example
    job.carp(cmd)

if __name__ == '__main__':
    run()