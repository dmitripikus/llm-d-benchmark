kubectl apply -f read-param-from-configmap-task.yaml
#kubectl apply -f store-param-to-configmap-task.yaml
kubectl apply -f store-param-to-env-configmap-task.yaml
kubectl apply -f get-pods-pipeline.yaml
kubectl delete pods -l tekton.dev/pipeline
