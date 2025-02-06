
#Basic Ventricular Stimulation script: Options to pulse for the desired strength, stim duration, no. pulses, bcl, start times for pulses, cell model and options to checkpoint. You can also choose the output resolution to save on simulation time.
# This script can specify ectopic beats from each of the 5 stimulus sites. 
import os

EXAMPLE_DESCRIPTIVE_NAME = 'Example of NSR'
EXAMPLE_AUTHOR = 'Hannah Lydon <k23086865@kcl.ac.uk'
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

    # Mesh specific arguments 
    group.add_argument('--mesh',
                       type = str, default = 'ventricles_coarser',
                      help = 'Simulation mesh (default is %(default)s)' )
    group.add_argument('--input_state',
                       type = str, default = "1_NSR_input_3200.roe",
                       help = 'Checkpointed State at which to start the ATP therapy from, default is %(default)s')
    group.add_argument('--conmul',
                       type = float, default = 1.0,
                       help = 'Multiplication factor for default conductivities (default is %(default)s)')
    group.add_argument('--tend',
                       type = float, default = 30000,
                       help = 'Duration of simulation (default is %(default)s) ms')
    group.add_argument('--model',
                        type = str,
                        default = "tenTusscherPanfilov", 
                        help='ionic model (default is %(default)s)')
    group.add_argument('--output_res',
                       type = float, default = 1,
                       help = 'Resolution of output for .igb files (default is %(default)s ms)')
    group.add_argument('--check',
                       type = float, default = 500,
                       help = 'Time interval for saving the state of the simulation (default is %(default)s ms, 0.5 seconds )')
    
    # arguments for the underlying NSR 
    group.add_argument('--pls',
                       type = float, default = 37,
                       help = 'Number of pulses (default is %(default)s)')
    group.add_argument('--bcl',
                        type = float, default = 800,
                        help = 'BCL of sinus pulses (default is %(default)s ms, 75bpm )')
    group.add_argument('--strength',
                        type = float, default = 450,
                        help = 'Strength for the stimulation (default is %(default)s muA)')
    group.add_argument('--duration',
                        type = float, default = 4,
                        help = 'Duration for the stimulation (default is %(default)s  ms)')
    group.add_argument('--start',
                       type = float, default = 0,
                       help = 'Start time of whole heart stimulation (default is %(default)s ms)')
    

    # arguments for the focal beats 
    group.add_argument('--ectopic', 
                       type = str, default = "coarse_focal.vtx",
                       help = 'Site for ectopic beat (default is %(default)s)')
    group.add_argument('--focal_start',
                       type = float, default = 3200,
                       help = 'Start time for the focal beat (default is %(default)s ms)')
    group.add_argument('--episodes',
                       type = float, default = 1,
                       help = 'Number of focal episodes (default is %(default)s')
    group.add_argument('--episode_interval',
                       type = float, default = 1000,
                       help = 'Time delay between focal episodes (default is %(default)s)')
    group.add_argument('--focal_pls',
                       type = float, default = 27,
                       help = 'Number of ectopic pulses (default is %(default)s)')
    group.add_argument('--focal_bcl',
                        type = float, default = 360,
                        help = 'BCL pulses (default is %(default)s ms, 75bpm )')
    group.add_argument('--focal_strength',
                        type = float, default = 350,
                        help = 'Strength for the stimulation (default is %(default)s muA)')
    group.add_argument('--focal_duration',
                        type = float, default = 2,
                        help = 'Duration for the stimulation (default is %(default)s  ms)')
   

    return parser

# Focal Episode time calculations 
def calculate_start_times(args):
    start_times = [args.focal_start]
    current_start = args.focal_start # Initiate the start time for the first focal episode 
    
    for i in range(1, int(args.episodes)):
        next_start = current_start + i * args.episode_interval
        start_times.append(next_start)
        current_start = next_start

    return start_times

def jobID(args):
    today = date.today()
    ID = '{}_{}_Focal_VT_{}_{:.2f}_episodes_{:.2f}_focal_bcl_{:.2f}_focal_pls_{:.2f}_focal_strength_{:.2f}_focal_duration'.format(today.isoformat(), args.input_state, args.ectopic, args.episodes, args.focal_bcl,
                                args.focal_pls, args.focal_strength, args.focal_duration)

    return ID

@tools.carpexample(parser, jobID)
def run(args, job):

    # Generate general command line
    cmd = tools.carp_cmd()

    # Set output directory
    cmd += ['-simID', job.ID]

    # Add some example-specific command line options
    cmd += ['-meshname', args.mesh,
            '-tend', args.tend,
            '-start_statef', args.input_state,
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
    



     #Define the conductivities - this depends on the mesh that you use:

    if 'infarct' in args.mesh:
        # Adjust conductivity if infarct is detected

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
    		'-gregion[2].g_el', 		0.799,	# extracellular conductivity in longitudinal direction
    		'-gregion[2].g_et', 		0.358,	# extracellular conductivity in transverse direction
    		'-gregion[2].g_en', 		0.237,	# extracellular conductivity in sheet direction
    		'-gregion[2].g_il', 		0.222,	# intracellular conductivity in longitudinal direction
    		'-gregion[2].g_it', 		0.1,	# intracellular conductivity in transverse direction
    		'-gregion[2].g_in', 		0.067,	# intracellular conductivity in sheet direction
    		'-gregion[2].g_mult',		args.conmul, #scale all conducitivites by a factor (to alter conduction velocity) 

                   ]

    else: 

        cmd += ['-num_gregions',			1,
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
    		'-gregion[0].g_mult',		args.conmul, # scale all conducitivites by a factor (to alter conduction velocity)   

                ]


  
    #Define the stimulus, an underlying NSR rhythm with a varying number of focal beat episodes on top. 
    #start tiimes for the episodes are pre-calculated:
    episode_start_times = calculate_start_times(args) 
    

# Set the base number of stimuli (5 NSR stimuli)
    cmd += ['-num_stim', 5 + int(args.episodes)]  # Add the number of focal episodes to the total number of stimuli

    #add NSR stimuli 
    cmd += [
            
           '-stimulus[0].vtx_fcn', 1,
           '-stimulus[0].vtx_file', "LV_af.vtx",
           '-stimulus[0].stimtype',  0,
           '-stimulus[0].strength', args.strength,
           '-stimulus[0].duration', args.duration,
           '-stimulus[0].start', args.start,
           '-stimulus[0].npls', args.tend // args.bcl,
           '-stimulus[0].bcl',  args.bcl,

           '-stimulus[1].vtx_fcn', 1,
           '-stimulus[1].vtx_file', "LV_pf.vtx",
           '-stimulus[1].stimtype',  0,
           '-stimulus[1].strength', args.strength,
           '-stimulus[1].duration', args.duration,
           '-stimulus[1].start', args.start,
           '-stimulus[1].npls',  args.tend // args.bcl,
           '-stimulus[1].bcl',  args.bcl,

           '-stimulus[2].vtx_fcn', 1,
           '-stimulus[2].vtx_file', "LV_sf.vtx",
           '-stimulus[2].stimtype',  0,
           '-stimulus[2].strength', args.strength,
           '-stimulus[2].duration', args.duration,
           '-stimulus[2].start', args.start,
           '-stimulus[2].npls',  args.tend // args.bcl,
           '-stimulus[2].bcl',  args.bcl,

           '-stimulus[3].vtx_fcn', 1,
           '-stimulus[3].vtx_file', "RV_mod.vtx",
           '-stimulus[3].stimtype',  0,
           '-stimulus[3].strength', args.strength,
           '-stimulus[3].duration', args.duration,
           '-stimulus[3].start', args.start,
           '-stimulus[3].npls',  args.tend // args.bcl,
           '-stimulus[3].bcl',  args.bcl,

           '-stimulus[4].vtx_fcn', 1,
           '-stimulus[4].vtx_file', "RV_sf.vtx",
           '-stimulus[4].stimtype',  0,
           '-stimulus[4].strength', args.strength,
           '-stimulus[4].duration', args.duration,
           '-stimulus[4].start', args.start,
           '-stimulus[4].npls', args.tend // args.bcl,
           '-stimulus[4].bcl',  args.bcl,
        ]

#Arguments for the focal episodes, same parameters, with options to vary the number and spacing of the episodes
    for i in range(int(args.episodes)):
        #print(i)
        #print(atp_start_times[i])
        cmd += [
                f'-stimulus[{5 + i}].vtx_fcn', 1,
                f'-stimulus[{5 + i}].vtx_file', args.ectopic,
                f'-stimulus[{5 + i}].stimtype', 0,
                f'-stimulus[{5 + i}].strength', args.focal_strength,
                f'-stimulus[{5 + i}].duration', args.focal_duration,
                f'-stimulus[{5 + i}].bcl', args.focal_bcl,
                f'-stimulus[{5 + i}].start', episode_start_times[i],
                f'-stimulus[{5 + i}].npls', args.focal_pls,
            ]

      #Define outputs and postprocesses
    cmd += ['-spacedt', args.output_res,
            '-timedt', 1.0,
            ]
    
    cmd += ['-chkpt_start', 0,
            '-chkpt_intv',  args.check,
            ]
    
      #Define phie points 
    
    cmd += [
             '-post_processing_opts', 1, 
             '-phie_rec_ptf', 'electrodesICD',
             '-phie_recovery_file', 'phie',
             '-phie_rec_meth', 1,
               ]
    


    # Run example
    job.carp(cmd)

if __name__ == '__main__':
    run()