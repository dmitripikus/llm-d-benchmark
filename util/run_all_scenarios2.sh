#epps=(baseline load estimate)
epps=(estimate)
#epps=(baseline cache_tracking)

#workloads=(shared_prefix_synthetic_exp1 shared_prefix_synthetic_exp2 shared_prefix_synthetic_exp3)
workloads=(shared_prefix_synthetic_exp1_8)

for epp in "${epps[@]}"; do 
    for workload in "${workloads[@]}"; do 
        util/run_scenario.sh -w $workload -e $epp -c $(realpath ./inf_perf_env.sh); 
    done; 
done
