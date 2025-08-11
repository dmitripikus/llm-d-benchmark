
# estimate
# for epp in estimate; do 
#     for workload in shared_prefix_synthetic_exp1; do 
#         util/run_scenario.sh -w $workload -e $epp -c $(realpath ./inf_perf_env.sh); 
#     done; 
# done

# cache_tracking
for epp in cache_tracking; do 
    for workload in shared_prefix_synthetic_exp1; do 
        util/run_scenario.sh -w $workload -e $epp -c $(realpath ./inf_perf_env.sh); 
    done; 
done




# for epp in cache_tracking baseline estimate load; 
#     do for workload in shared_prefix random; 
#         do util/run_scenario.sh -w $workload -e $epp -c $(realpath ../baseenv.sh); 
#         done; 
#     done    