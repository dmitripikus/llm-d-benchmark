export LLMDBENCH_CONTROL_WORK_DIR=/Users/dpikus/DP_FILES/Data/projects/llm-d/kv-cache-benchmarking/LLM-D-BENCHMARK/inference-perf
export LLMDBENCH_HF_TOKEN=$(oc get secrets llm-d-hf-token -o jsonpath='{.data.*}' | base64 -d)

# export LLMDBENCH_IMAGE_REGISTRY=quay.io
# export LLMDBENCH_IMAGE_REPO="deanlorenz"
# export LLMDBENCH_IMAGE_NAME="llm-d-benchmark"
# export LLMDBENCH_IMAGE_TAG="03-08"