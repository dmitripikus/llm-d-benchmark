curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"username": "Tekton2"}' \
  http://el-mylistener.mynamespace.svc.cluster.local:8080


  curl -v \
   -H 'content-Type: application/json' \
   -d '{"username": "Tekton2"}' \
   http://localhost:8080


tkn pipeline start get-pods-pipeline -n dpikus-ns --serviceaccount inference-perf-runner -p config="$(cat config.yaml)"   