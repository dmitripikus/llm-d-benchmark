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

export NAMESPACE=pytorch-conference-precise
export MODEL='Qwen/Qwen3-32B'
epps=(load precise)
workloads=(gto)


for epp in "${epps[@]}"; do 
    for workload in "${workloads[@]}"; do 
        util/run_scenario.sh -w $workload -e $epp -c $(realpath util/gto_env.sh); 
    done; 
done
