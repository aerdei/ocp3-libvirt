for i in {10..20}
  do
    oc create -f -<<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  labels:
    logging: "true" 
  name: pv${i}
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 5Gi
  nfs:
    path: /exports/pv/pv${i}
    server: 192.168.122.7
  persistentVolumeReclaimPolicy: Recycle
EOF
  done

