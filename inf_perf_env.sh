export LLMDBENCH_CONTROL_WORK_DIR=/Users/dpikus/DP_FILES/Data/projects/llm-d/kv-cache-benchmarking/LLM-D-BENCHMARK/inference-perf
export LLMDBENCH_HF_TOKEN=$(oc get secrets llm-d-hf-token -o jsonpath='{.data.*}' | base64 -d)
export LLMDBENCH_VLLM_COMMON_PVC_NAME=dima-hash-fix-chart-llama-3-70b-instruct-storage-claim

export LLMDBENCH_IMAGE_REGISTRY=quay.io
export LLMDBENCH_IMAGE_REPO="dpikus"
export LLMDBENCH_IMAGE_NAME="llm-d-benchmark"
export LLMDBENCH_IMAGE_TAG="v0.2.2_fix"
