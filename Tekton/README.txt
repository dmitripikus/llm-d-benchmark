curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "Tekton2"}' \
  http://el-mylistener.mynamespace.svc.cluster.local:8080


  curl -v \
   -H 'content-Type: application/json' \
   -d '{"username": "Tekton2"}' \
   http://localhost:8080


tkn pipeline start get-pods-pipeline -n dpikus-ns --serviceaccount inference-perf-runner -p config="$(cat config.yaml)"   



Install run on pod:



oc run my-kubectl \
  -it \
  --restart=Never \
  --overrides='
{
  "apiVersion": "v1",
  "kind": "Pod",
  "spec": {
    "serviceAccountName": "inference-perf-runner",
    "containers": [
      {
        "name": "my-kubectl",
        "image": "ubuntu:22.04",
        "stdin": true,
        "tty": true,
        "command": ["bash"],
        "securityContext": {
          "runAsUser": 0,
          "runAsGroup": 0
        }
      }
    ],
    "restartPolicy": "Never"
  }
}'


apt update
apt install -y git
git clone --branch fusionv6-llm-d-inference-scheduling-env --single-branch https://github.com/dmitripikus/llm-d-benchmark.git
cd llm-d-benchmark/
sed -i 's/sudo //g' ./setup/install_deps.sh
./setup/install_deps.sh

export LLMDBENCH_HF_TOKEN=$HF_TOKEN

export LLMDBENCH_IMAGE_REGISTRY=quay.io
export LLMDBENCH_IMAGE_REPO="dpikus"
export LLMDBENCH_IMAGE_NAME="llm-d-benchmark"
export LLMDBENCH_IMAGE_TAG="v0.2.2_fix"

export LLMDBENCH_VLLM_COMMON_PVC_NAME="model-cache-pvc"
export LLMDBENCH_VLLM_COMMON_PVC_STORAGE_CLASS="ocs-storagecluster-cephfs"



oc run my-kubectl --image=ubuntu:22.04 -it --overrides='
{
  "apiVersion": "v1",
  "kind": "Pod",
  "spec": {
    "serviceAccountName": "inference-perf-runner",
    "containers": [
      {
        "name": "my-kubectl",
        "image": "ubuntu:22.04",
        "stdin": true,
        "tty": true,
        "securityContext": {
          "runAsUser": 0,
          "runAsGroup": 0
        }
      }
    ],
    "restartPolicy": "Never"
  }
}'   -- bash



oc run my-kubectl --image=ubuntu:22.04 -it --overrides='
{
  "apiVersion": "v1",
  "kind": "Pod",
  "spec": {
    "serviceAccountName": "inference-perf-runner",
    "containers": [
      {
        "name": "my-kubectl",
        "image": "ubuntu:22.04",
        "stdin": true,
        "tty": true,
        "securityContext": {
          "runAsUser": 0,
          "runAsGroup": 0
        },
        "command": [
            "sh",
            "-c",
            "apt-get update && apt-get install -y curl && mkdir -p /root/.kube && SERVER=https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT && TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) && CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt && curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin/ && kubectl config set-cluster in-cluster --server=$SERVER --certificate-authority=$CA --embed-certs=true && kubectl config set-credentials sa-user --token=$TOKEN && kubectl config set-context sa-context --cluster=in-cluster --user=sa-user && kubectl config use-context sa-context && exec bash"
]      }
    ],
    "restartPolicy": "Never"
  }
}'   -- bash





add-role-to-user view system:serviceaccount:dpikus-ns:inference-perf-runner -n dpikus-ns



Command: 
tkn pipeline start get-pods-pipeline -n dpikus-ns --serviceaccount inference-perf-runner -p config="$(cat config.yaml)" -w name=shared-workspace,emptyDir=""

tkn pipeline start get-pods-pipeline -n dpikus-ns --serviceaccount helm-installer -p config="$(cat config.yaml)" -w name=shared-workspace,emptyDir=""