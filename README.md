# sandstorm
Insurgency: Sandstorm Docker Container

## Credits
These should go at the top because I'm standing on the shoulders of giants here. This could not be possible at all without the amazing work [linuxgsm](https://linuxgsm.com) or someone who I have lost over the years who wrote this initial Dockerfile and script. Thank you to everyone who played a role in getting this out there.

This is a [linuxgsm](https://linuxgsm.com/) sandstorm container. I use it in Kubernetes to deploy and run my Insurgency: Sandstorm server. If you want persistence, map in /insurgency. I have set this up on GCP and also on my home Kubernetes cluster.

This container isn't huge and will download the game to the /insurgency directory when it starts. This is the "benefit" and side-effect of updating after the image was made and also quicker startup. That means something can change in the game and break this container since it will download new data on startup. I preferred this to a massive container that would need to update almost immediately. Why download the data twice?

Once started, most interesting files like the mapcycle are found in /insurgency, which is the working directory for the container. If you've mapped in storage, once booted you can see and edit the things inside that directory and restart the server.

## Kubernetes Setup:
I use the following yaml to define the setup. Alter with your IPs for storage:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sandstorm
  labels:
    app: sandstorm
    version: v0
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sandstorm
      version: v0
  template:
    metadata:
      labels:
        app: sandstorm
        version: v0
    spec:
      containers:
      - name: sandstorm
        image: knobby/sandstorm
        resources:
          limits:
            cpu: 1
            memory: 4Gi
        volumeMounts:
        - name: sandstorm-store
          mountPath: /insurgency
        ports:
        - containerPort: 27102
          name: insurg-main-udp
          protocol: UDP
        - containerPort: 27131
          name: insurg-query
          protocol: UDP
        imagePullPolicy: Always
      volumes:
      - name: sandstorm-store
        persistentVolumeClaim:
          claimName: sandstorm

---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: sandstorm
spec:
  accessModes:
    - ReadWriteOnce
  selector:
    matchLabels:
      name: "sandstorm"
  resources:
    requests:
      storage: 200Gi

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: sandstorm
  labels:
    name: sandstorm
spec:
  capacity:
    storage: 200Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    path: /mnt/path/to/sandstorm
    server: <you nfs server>

---
apiVersion: v1
kind: Service
metadata:
  name: sandstorm
  labels:
    app: sandstorm
    kubernetes.io/name: "sandstorm"
spec:
  selector:
    app: sandstorm
  ports:
  - name: insurg-main-udp
    port: 27102
    protocol: UDP
  - name: insurg-query
    port: 27131
    protocol: UDP
  type: LoadBalancer
```

## GCP setup:
Had to use an Ubuntu server before the scripts would run correctly for some reason. Just spun up a GCP instance of Ubuntu 18.04 and then set this file in /etc/systemd/system/sandstorm.service:
```
[Unit]
Description=Start up sandstorm docker container
Requires=docker.service
Wants=network-online.target
After=network-online.target

[Service]
ExecStartPre=-/usr/bin/docker rm sandstorm
ExecStartPre=/usr/bin/docker pull knobby/sandstorm
ExecStart=/usr/bin/docker run --rm --name=sandstorm --net=host -v /home/insurgency:/insurgency -v /etc/localtime:/etc/localtime knobby/sandstorm
ExecStop=/usr/bin/docker stop sandstorm
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Known Issues:
Some of the symlinks aren't setup correctly yet, but the files exist down in the /insurgency directory.
