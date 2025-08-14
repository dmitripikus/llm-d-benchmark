export LLMDBENCH_CONTROL_WORK_DIR=/Users/dpikus/DP_FILES/Data/projects/llm-d/kv-cache-benchmarking/LLM-D-BENCHMARK/fmperf/dev_fmperf_exp1
export LLMDBENCH_HF_TOKEN=$(oc get secrets llm-d-hf-token -o jsonpath='{.data.*}' | base64 -d)
export LLMDBENCH_HARNESS_CONTAINER_IMAGE=quay.io/dpikus/lm-benchmark:upstreamfixed


# export LLMDBENCH_HARNESS_CONTAINER_IMAGE="quay.io/gilshar/lm-benchmark-apps:0.0.1"
# export LLMDBENCH_HARNESS_GIT_REPO="https://github.com/SharonGil/fmperf.git"
# export LLMDBENCH_HARNESS_GIT_BRANCH="dev-lmbenchmark"

export LLMDBENCH_IMAGE_REGISTRY=quay.io
export LLMDBENCH_IMAGE_REPO="deanlorenz"
export LLMDBENCH_IMAGE_NAME="llm-d-benchmark"
export LLMDBENCH_IMAGE_TAG="0.0.2"
