#RAMP ATP SCRIPT: User must define the default mesh and electrode stimulation points. 
#Optional arguments can be found in the parser

import os
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
                       type = str,
                      help = 'Simulation mesh (Must be specified)' )
    group.add_argument('--myocardium',
                       type = float, 
                       help = 'Region Tag for the myocardium (Must be specified)')
    group.add_argument('--scar_flag',
                       type = bool, choices = [0,1], default = 1,
                       help = 'Flag for assigning conductivities to regions of scar tissue (1 for meshes with scarring, 0 for meshes without. Default is %(default)s)'
                       )
    group.add_argument('--scar_region',
                       type = float, 
                       help = 'Region Tag for scarring (Must be specified for meshes with scar tissue, omit if none are present)')
    group.add_argument('--isthmus_region',
                       type = float, 
                       help = 'Region Tag for the isthmus (Must be specified for meshes with isthmuses, omit if none are present)')
    group.add_argument('--conmul',
                       type = float, default = 1.0,
                       help = 'Multiplication factor for conductivity in the isthmus (default is %(default)s)')
    group.add_argument('--input_state',
                       type = str, 
                       help = 'Checkpointed State at which to start the ATP therapy from (Must be specified)')
    group.add_argument('--model',
                        type = str,
                        default = "tenTusscherPanfilov", 
                        help='ionic cell model (default is %(default)s)')
    
   #Length of full simulation run-time - remember the time stamp of the input state! 
    group.add_argument('--tend',
                       type = float, default = 30000,
                       help = 'Duration of simulation (default is %(default)s) ms')
    
    #NSR arguments 
    group.add_argument('--bcl',
                        type = float, default = 800,
                        help = 'BCL for NSR (default is %(default)s ms, 75bpm )')
    group.add_argument('--strength',
                        type = float, default = 450,
                        help = 'Strength for the NSR stimulation (default is %(default)s muA)')
    group.add_argument('--duration',
                        type = float, default = 4,
                        help = 'Duration for the NSR stimulation (default is %(default)s  ms)')
    group.add_argument('--start',
                       type = float, default = 0,
                       help = 'Start time of whole heart NSR stimulation (default is %(default)s ms)')
    group.add_argument('--NSR_vtx', 
                       type = str,
                       help = '.vtx file for NSR stimulus site (Must be specified)')
    
   # Output arguments, resolution of the output files and checn checkpoints are generated 
    group.add_argument('--electrodes',
                       type = str,
                       help = 'Name of .pts file for the ICD electrodes, from which phie is recovered (Must be specified)')
    group.add_argument('--output_res',
                       type = float, default = 1,
                       help = 'Resolution of output for .igb files (default is %(default)s ms)')
    group.add_argument('--check',
                       type = float, default = 1000,
                       help = 'Time interval for saving the state of the simulation (default is %(default)s ms, 1 second )')
    
    
    #Arguments for the simulation of ATP. 
    group.add_argument('--ATP_start',
                       type = float, default = 0,
                       help = 'Start time the ATP burst (default is %(default)s ms)')
    group.add_argument('--ATP_pls',
                       type = float, default = 8,
                       help = 'Number of pulses (default is %(default)s)')
    group.add_argument('--ATP_cl',
                        type = float,
                        help = 'Cycle length of ATP pulses (Must be specified)') 
    group.add_argument('--ATP_strength',
                        type = float,
                        help = 'Strength for the ATP stimulation (default is twice the strength of NSR stimulus strength)') 
    group.add_argument('--ATP_duration',
                        type = float, default = 5,
                        help = 'Pulse Duration for the ATP stimulation (default is %(default)s  ms)') 
    group.add_argument('--ATP_stimsite',
                       type = str, 
                       help = 'Pacing site for the ATP (Must be specified)') 
    group.add_argument('--ATP_dec',
                       type = float, default = 10 ,
                       help = 'Decrement of the ATP cycle length during a burst (default is %(default)s)')
    group.add_argument('--ATP_Min_Cycle',
                       type = float, default = 220,
                        help = 'Minimum Cycle Length of ATP (default is %(defaults)s)' )

    return parser



# Ramp time calculations 
def calculate_start_times(args):
    start_times = [args.ATP_start]
    current_start = args.ATP_start

    #Minimum cycle length check 
    if args.ATP_cl < args.ATP_Min_Cycle:
        ATP_cl = args.ATP_Min_Cycle
    else:
        ATP_cl = args.ATP_cl 
    
    for i in range(0, int(args.ATP_pls)):
        next_start = current_start + ATP_cl - i * args.ATP_dec
        if next_start - current_start < args.ATP_Min_Cycle:
            next_start = current_start + args.ATP_Min_Cycle
        start_times.append(next_start)
        current_start = next_start

    return start_times


def jobID(args):
    today = date.today()
    ID = '{}_ATP_APP_INPUT_{}_{:.2f}_atpbcl_{:.2f}_atpstart_{:.2f}_atpdec_{:.2f}_atppls'.format(today.isoformat(), args.input_state, args.ATP_cl, args.ATP_start, args.ATP_dec, args.ATP_pls
                                                                                           )
    

    return ID

@tools.carpexample(parser, jobID)
def run(args, job):

    #ATP stimulus trength check
    if args.ATP_strength is None:
         args.ATP_strength = 2*args.strength 

    # Generate general command line
    cmd = tools.carp_cmd()

    # Set output directory
    cmd += ['-simID', job.ID]

    # Add some example-specific command line options
    cmd += ['-meshname', args.mesh,
            '-start_statef', args.input_state,
            '-tend', args.tend,
            '-gridout_i', 3,
    ]
    
    #Define phie points 
    cmd += [
             '-phie_rec_ptf', args.electrodes,
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

   
    #Define the conductivities. User must add in their own values or openCARP defaults will be used.  
    #User must define the regions for myocardium, scar regions and isthmus regions (if present). Border Zone (BZ) regions can be added if desired by the user:
    #Note: Mondomain conductivites will be calculated as half of the harmonic mean of intracellular and extracellular conductivities

    if args.scar_flag == 1:
        # Adjust conductivity if scarring is present in the mesh
            cmd += ['-num_gregions',			3,
                    

    		'-gregion[0].name', 		"Myocardium",
            '-gregion[0].num_IDs', 1,
            '-gregion[0].ID[0]', args.myocardium,
            
    		
    		'-gregion[0].g_el', 		# extracellular conductivity in longitudinal direction
    		'-gregion[0].g_et', 		# extracellular conductivity in transverse direction
    		'-gregion[0].g_en', 		# extracellular conductivity in sheet direction
    		'-gregion[0].g_il', 		# intracellular conductivity in longitudinal direction
    		'-gregion[0].g_it', 		# intracellular conductivity in transverse direction
    		'-gregion[0].g_in', 		# intracellular conductivity in sheet direction  

            '-gregion[1].name', 		"Scar",
            '-gregion[1].num_IDs', 1,
            '-gregion[1].ID[0]', args.scar_region,
    		

    		'-gregion[1].g_el', 		# extracellular conductivity in longitudinal direction
    		'-gregion[1].g_et', 		# extracellular conductivity in transverse direction
    		'-gregion[1].g_en', 		# extracellular conductivity in sheet direction
    		'-gregion[1].g_il', 		# intracellular conductivity in longitudinal direction
    		'-gregion[1].g_it', 		# intracellular conductivity in transverse direction
    		'-gregion[1].g_in', 		# intracellular conductivity in sheet direction
    		

            '-gregion[2].name', 		"Isthmus",
            '-gregion[2].num_IDs', 1,
            '-gregion[2].ID[0]', args.isthmus_region,
           
    		'-gregion[2].g_el', 		# extracellular conductivity in longitudinal direction
    		'-gregion[2].g_et', 		# extracellular conductivity in transverse direction
    		'-gregion[2].g_en', 		# extracellular conductivity in sheet direction
    		'-gregion[2].g_il', 		# intracellular conductivity in longitudinal direction
    		'-gregion[2].g_it', 		# intracellular conductivity in transverse direction
    		'-gregion[2].g_in', 		# intracellular conductivity in sheet direction
    		'-gregion[2].g_mult',		args.conmul, #scale all conducitivites by a factor (to alter conduction velocity) 


                   ]

    else: 

        cmd += ['-num_gregions',			1,
                

    		'-gregion[0].name', 		"Myocardium",
            '-gregion[0].num_IDs', 1,
            '-gregion[0].ID[0]', args.myocardium,
          
    
    		'-gregion[0].g_el', 		# extracellular conductivity in longitudinal direction
    		'-gregion[0].g_et', 		# extracellular conductivity in transverse direction
    		'-gregion[0].g_en', 		# extracellular conductivity in sheet direction
    		'-gregion[0].g_il', 		# intracellular conductivity in longitudinal direction
    		'-gregion[0].g_it', 		# intracellular conductivity in transverse direction
    		'-gregion[0].g_in', 		# intracellular conductivity in sheet direction
                ]




#Define the stimulus - underlying NSR rhythm that continues underneath the arrhythmia episode and the application of the ATP. 
# ATP stimulus - Ramp Scheme - The time between pulses decreases for each beat of the ATP burst
    atp_start_times = calculate_start_times(args)  # Dynamically calculate ATP pulse start times based on args.ATP_pls

# Set the base number of stimuli (1 NSR stimulus file)
    cmd += ['-num_stim', 1 + int(args.ATP_pls)]  # Add the number of ATP pulses to the total number of stimuli
    
# Add NSR stimuli (as before)
    cmd += [
              #NSR stimulus
           '-stimulus[0].vtx_fcn', 1,
           '-stimulus[0].vtx_file', args.NSR_vtx,
           '-stimulus[0].stimtype',  0, #Transmembrane Stimulus
           '-stimulus[0].strength', args.strength,
           '-stimulus[0].duration', args.duration,
           '-stimulus[0].start', args.start,
           '-stimulus[0].npls',  args.tend/args.bcl,
           '-stimulus[0].bcl',  args.bcl,
        ]

        # Loop through the number of ATP pulses based on the dynamic flag --ATP_pls
    for i in range(int(args.ATP_pls)):
        cmd += [
                f'-stimulus[{i}].vtx_fcn', 1,
                f'-stimulus[{i}].vtx_file', args.ATP_stimsite,
                f'-stimulus[{i}].stimtype', 0, #Transmembrane Stimulus
                f'-stimulus[{i}].strength', args.ATP_strength,
                f'-stimulus[{i}].duration', args.ATP_duration,
                f'-stimulus[{i}].start', atp_start_times[i],
                f'-stimulus[{i}].npls', 1,
            ]


      #Define outputs and postprocesses
    cmd += ['-spacedt', args.output_res,
            '-timedt', 1.0,
            ]
    #Define the states to save - you only need the final state. 
    cmd += ['-num_tsav', 1,
            '-tsav', args.tend,
            '-tsav_ext', f'ATP_end_{args.tend}'
           ]

#Define phie points 
    
    cmd += [
             '-post_processing_opts', 1, 
             '-phie_rec_ptf', args.electrodes,
             '-phie_recovery_file', 'phie',
             '-phie_rec_meth', 1,
               ]


    # Run example
    job.carp(cmd)

if __name__ == '__main__':
    run()