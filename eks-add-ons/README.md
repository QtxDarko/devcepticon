# TIPS

## Access kubernetes dashboard
```
kubectl -n kubernetes-dashboard port-forward deploy/kubernetes-dashboard 9090
```

Head to http://localhost:9090

## Access prometheus
```
kubectl -n prometheus port-forward deploy/prometheus-server 9090
```

Head to http://localhost:9090

### Install sample application to test cluster autoscaler
```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install es bitnami/elasticsearch
```


### Usefull commands
```
kubectl patch ingress prometheus-server -p '{"metadata":{"finalizers":[]}}' --type=merge
```
