#Simulation script for scar related reentrant VT: User must define the mesh, electrodes and the characteristics of the episode.

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

    #Define the stimulus
    cmd += ['-num_stim',  1,
            
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
             '-phie_rec_ptf', args.electrodes,
             '-phie_recovery_file', 'phie',
             '-phie_rec_meth', 1
          
               ]


    # Run example
    job.carp(cmd)

if __name__ == '__main__':
    run()