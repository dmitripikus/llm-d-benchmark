#epps=(baseline load estimate)
#epps=(estimate)

# Scheduler experiment 2
# epps=(sched_random shed_load_kvcache_util shed_load_only shed_active_req_kvcache_util)
# workloads=(sched_synthetic)


# Scheduler experiment - prefix-only vs prefix+load, with shared prefix, long input
# epps=(sched_estimate sched_estimate_load)
# workloads=(shared_prefix_synthetic_long_input)


# Scheduler experiment - prefix-only with shared prefix, long input (TEMP run - for logs only)
# epps=(sched_estimate)
# workloads=(shared_prefix_synthetic_long_input)

# Scheduler experiment - prefix+load with shared prefix, long input (TEMP run - for logs only)
# epps=(sched_estimate_load)
# workloads=(shared_prefix_synthetic_long_input)

# Scheduler experiment - prefix-only(precise) with shared prefix, long input (TEMP run - for logs only)
#epps=(sched_cache_tracking_only sched_cache_tracking_load)
#epps=(sched_cache_tracking_only)
# epps=(sched_cache_tracking_load)
# workloads=(shared_prefix_synthetic_long_input2)


# Scheduler experiment - prefix-only vs prefix+load, with NO shared prefix, long input
#epps=(sched_cache_tracking_only sched_cache_tracking_load)
epps=(sched_cache_tracking_load)
workloads=(sched_random_constant3)

# Scheduler experiment 3
# epps=(sched_random shed_load_only)
# workloads=(sched_synthetic_modified)




# Scheduler - new load scorer
# epps=(sched_random shed_active_req_kvcache_util)
# workloads=(sched_synthetic)

# Scheduler - load only (GIE impl)
# epps=(sched_random shed_load_only)
# workloads=(sched_synthetic)


#workloads=(shared_prefix_synthetic_exp1 shared_prefix_synthetic_exp2 shared_prefix_synthetic_exp3)

#short test
#epps=(shed_active_req_kvcache_util)
#workloads=(sched_synthetic_short)

for epp in "${epps[@]}"; do 
    for workload in "${workloads[@]}"; do 
        util/run_scenario.sh -w $workload -e $epp -c $(realpath ./inf_perf_env.sh) -l inference-perf; 
    done; 
done
