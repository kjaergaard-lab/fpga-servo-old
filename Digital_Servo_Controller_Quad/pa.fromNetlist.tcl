
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name Digital_Servo_Controller_Quad -dir "C:/Users/rjthomas/Documents/University of Otago/FPGA/Digital_Servo_Controller_Quad/planAhead_run_1" -part xc6slx45csg324-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/rjthomas/Documents/University of Otago/FPGA/Digital_Servo_Controller_Quad/topmod.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/rjthomas/Documents/University of Otago/FPGA/Digital_Servo_Controller_Quad} {ipcore_dir} }
add_files "ipcore_dir/K_Multiplier.ncf" -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_param project.paUcfFile  "Constraints.ucf"
add_files "Constraints.ucf" -fileset [get_property constrset [current_run]]
open_netlist_design
