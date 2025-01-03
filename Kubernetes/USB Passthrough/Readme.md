# Introduction

This guide will give you step by step instructions on how to pass a USB device to a POD on your RKE2 Cluster.

## Prerequisites

I assume you fullfill these prerequesites:

* RKE2 is already setup and running

## Instructions

### Step 1: Installing Akri

Needed for access to USB drives

#### 1. Add helm repo

```shell
helm repo add akri-helm-charts https://project-akri.github.io/akri/
```

#### 2. Inspect the values

Using `helm show values akri-helm-charts/akri` we can take a look at all values akri has (an we can manipulate):
<details>
  <summary>Akri values:</summary>

  ```yaml
  # Default values for akri.
  # This is a YAML-formatted file.
  # Declare variables to be passed into your templates.

  # useLatestContainers is specified if the latest or latest-dev
  # tags should be used.  This will be overridden if *.image.tag
  # is specified.
  useLatestContainers: false

  # useDevelopmentContainers is specified if the non-release (*-dev)
  # tags should be used.  This will be overridden if *.image.tag
  # is specified.
  useDevelopmentContainers: false

  # imagePullSecrets is the array of secrets needed to pull images.
  # This can be set from the helm command line using `--set imagePullSecrets[0].name="mysecret"`
  imagePullSecrets: []

  cleanupHook:
    # enabled defines whether to enable the Helm pre-delete hook to cleanup
    # Configurations during chart deletion. Also applies associated RBAC for the
    # hook. More information on Helm hooks:
    # https://helm.sh/docs/topics/charts_hooks/
    enabled: true

  # generalize references to `apiGroups` and `apiVersion` values for Akri CRDs
  crds:
    group: akri.sh
    version: v0

  rbac:
    # enabled defines whether to apply rbac to Akri
    enabled: true

  prometheus:
    # enabled defines whether metrics ports are exposed on
    # the Controller and Agent
    enabled: false
    # endpoint is the path the port exposed for metrics
    endpoint: /metrics
    # port is the port that the metrics service is exposed on
    port: 8080
    # portName is the name of the metrics port
    portName: metrics

  controller:
    # enabled defines whether to apply the Akri Controller
    enabled: true
    image:
      # repository is the Akri Controller container reference
      repository: ghcr.io/project-akri/akri/controller
      # tag is the Akri Controller container tag
      # controller.yaml will default to v(AppVersion)[-dev]
      # with `-dev` added if `useDevelopmentContainers` is specified
      tag:
      # pullPolicy is the Akri Controller pull policy
      pullPolicy: "Always"
    # ensures container doesn't run with unnecessary priviledges
    securityContext:
      runAsUser: 1000
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
    # onlyOnControlPlane dictates whether the Akri Controller will only run on nodes with
    # the label with (key, value) of ("node-role.kubernetes.io/master", "")
    onlyOnControlPlane: false
    # allowOnControlPlane dictates whether a toleration will be added to allow to Akri Controller
    # to run on the control plane node
    allowOnControlPlane: true
    # nodeSelectors is the array of nodeSelectors used to target nodes for the Akri Controller to run on
    # This can be set from the helm command line using `--set controller.nodeSelectors.label="value"`
    nodeSelectors: {}
    resources:
      # memoryRequest defines the minimum amount of RAM that must be available to this Pod
      # for it to be scheduled by the Kubernetes Scheduler
      memoryRequest: 11Mi
      # cpuRequest defines the minimum amount of CPU that must be available to this Pod
      # for it to be scheduled by the Kubernetes Scheduler
      cpuRequest: 10m
      # memoryLimit defines the maximum amount of RAM this Pod can consume.
      memoryLimit: 100Mi
      # cpuLimit defines the maximum amount of CPU this Pod can consume.
      cpuLimit: 26m

  agent:
    # enabled defines whether to apply the Akri Agent
    enabled: true
    # full specifies that the `agent-full` image should be used which has embedded Discovery Handlers
    full: false
    image:
      # repository is the Akri Agent container reference
      repository: ghcr.io/project-akri/akri/agent
      # fullRepository is the container reference for the Akri Agent with embedded Discovery Handlers
      fullRepository: ghcr.io/project-akri/akri/agent-full
      # tag is the Akri Agent container tag
      # agent.yaml will default to v(AppVersion)[-dev]
      # with `-dev` added if `useDevelopmentContainers` is specified
      tag:
      # pullPolicy is the Akri Agent pull policy
      pullPolicy: ""
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    host:
      # discoveryHandlers is the location of Akri Discovery Handler sockets and
      # the agent registration service
      discoveryHandlers: /var/lib/akri
      # kubeletDevicePlugins is the location of the kubelet device-plugin sockets
      kubeletDevicePlugins: /var/lib/kubelet/device-plugins
      # kubeletPodResources is the location of the kubelet pod-resources socket
      kubeletPodResources: /var/lib/kubelet/pod-resources
      # udev is the node path of udev, usually at `/run/udev`
      udev:
    # allowDebugEcho dictates whether the Akri Agent will allow DebugEcho Configurations
    allowDebugEcho: false
    # nodeSelectors is the array of nodeSelectors used to target nodes for the Akri Agent to run on
    # This can be set from the helm command line using `--set agent.nodeSelectors.label="value"`
    nodeSelectors: {}
    resources:
      # memoryRequest defines the minimum amount of RAM that must be available to this Pod
      # for it to be scheduled by the Kubernetes Scheduler
      memoryRequest: 11Mi
      # cpuRequest defines the minimum amount of CPU that must be available to this Pod
      # for it to be scheduled by the Kubernetes Scheduler
      cpuRequest: 10m
      # memoryLimit defines the maximum amount of RAM this Pod can consume.
      memoryLimit: 79Mi
      # cpuLimit defines the maximum amount of CPU this Pod can consume.
      cpuLimit: 26m

  custom:
    configuration:
      # enabled defines whether to load a custom configuration
      enabled: false
      # name is the Kubernetes resource name that will be created for this
      # custom configuration
      name: akri-custom
      # discoveryHandlerName is the name of the Discovery Handler the Configuration is using
      discoveryHandlerName:
      # brokerProperties is a map of properties that will be passed to any instances
      # created as a result of applying this custom configuration
      brokerProperties: {}
      # capacity is the capacity for any instances created as a result of
      # applying this custom configuration
      capacity: 1
      # discoveryDetails is the string of discovery details that is
      # passed to a Discovery Handler which can parse it into an expected format.
      discoveryDetails: ""
      brokerPod:
        image:
          # repository is the custom broker container reference
          repository:
          # tag is the custom broker image tag
          tag: latest
          # pullPolicy is the custom pull policy
          pullPolicy: ""
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 11Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 10m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 24Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 24m
      brokerJob:
        # container used by custom
        image:
          # repository is the custom broker container reference
          repository:
          # tag is the custom broker image tag
          tag: latest
          # pullPolicy is the custom pull policy
          pullPolicy: ""
        # command to be executed in the Pod. An array of arguments. Can be set like:
        # --set custom.configuration.brokerJob.command[0]="sh" \
        # --set custom.configuration.brokerJob.command[1]="-c" \
        # --set custom.configuration.brokerJob.command[2]="echo 'Hello World'"
        command:
        # restartPolicy for the Job. Can either be OnFailure or Never.
        restartPolicy: OnFailure
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 11Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 10m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 24Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 24m
        # backoffLimit defines the Kubernetes Job backoff failure policy. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy
        backoffLimit: 2
        # parallelism defines how many Pods of a Job should run in parallel. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs
        parallelism: 1
        # completions defines how many Pods of a Job should successfully complete. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job
        completions: 1
      # createInstanceServices is specified if a service should automatically be
      # created for each broker pod
      createInstanceServices: true
      instanceService:
        # name is the description of the instance service
        name: akri-custom-instance-service
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 6052
        # targetPort is the service targetPort of the instance service
        targetPort: 6052
        # protocol is the service protocol of the instance service
        protocol: TCP
      # createConfigurationService is specified if a single service should automatically be
      # created for all broker pods of a Configuration
      createConfigurationService: true
      configurationService:
        # name is the description of the configuration service
        name: akri-custom-configuration-service
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 6052
        # targetPort is the service targetPort of the instance service
        targetPort: 6052
        # protocol is the service protocol of the instance service
        protocol: TCP
    # discovery defines a set of values for a custom discovery handler DaemonSet
    discovery:
      # enabled defines whether discovery handler pods will be deployed in a slim Agent scenario
      enabled: false
      # name is the Kubernetes resource name that will be created for this
      # custom Discovery Handler DaemonSet
      name: akri-custom-discovery
      image:
        # repository is the custom broker container reference
        repository:
        # tag is the custom broker image tag
        tag: latest
        # pullPolicy is the pull policy
        pullPolicy: ""
      # useNetworkConnection specifies whether the discovery handler should make a networked connection
      # with Agents, using its pod IP address when registering
      useNetworkConnection: false
      # port specifies (when useNetworkConnection is true) the port on which the discovery handler advertises its discovery service
      port: 10000
      # nodeSelectors is the array of nodeSelectors used to target nodes for the discovery handler to run on
      # This can be set from the helm command line using `--set custom.discovery.nodeSelectors.label="value"`
      nodeSelectors: {}
      resources:
        # memoryRequest defines the minimum amount of RAM that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        memoryRequest: 11Mi
        # cpuRequest defines the minimum amount of CPU that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        cpuRequest: 10m
        # memoryLimit defines the maximum amount of RAM this Pod can consume.
        memoryLimit: 24Mi
        # cpuLimit defines the maximum amount of CPU this Pod can consume.
        cpuLimit: 24m

  debugEcho:
    configuration:
      # enabled defines whether to load a debugEcho configuration
      enabled: false
      # name is the Kubernetes resource name that will be created for this
      # debugEcho configuration
      name: akri-debug-echo
      # brokerProperties is a map of properties that will be passed to any instances
      # created as a result of applying this debugEcho configuration
      brokerProperties: {}
      # capacity is the capacity for any instances created as a result of
      # applying this debugEcho configuration
      capacity: 2
      discoveryDetails:
        # descriptions is the list of instances created as a result of
        # applying this debugEcho configuration
        descriptions:
        - "foo0"
        - "foo1"
      # shared defines whether instances created as a result of
      # applying this debugEcho configuration are shared
      shared: true
      brokerPod:
        # container used by debugEcho
        image:
          # repository is the debugEcho broker container reference
          repository:
          # tag is the debugEcho broker image tag
          tag: latest
          # pullPolicy is the debugEcho pull policy
          pullPolicy: ""
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 10Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 10m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 30Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 29m
      brokerJob:
        # container used by debugEcho
        image:
          # repository is the debugEcho broker container reference
          repository:
          # tag is the debugEcho broker image tag
          tag: latest
          # pullPolicy is the debugEcho pull policy
          pullPolicy: ""
        # command to be executed in the Pod. An array of arguments. Can be set like:
        # --set debugEcho.configuration.brokerJob.command[0]="sh" \
        # --set debugEcho.configuration.brokerJob.command[1]="-c" \
        # --set debugEcho.configuration.brokerJob.command[2]="echo 'Hello World'" \
        command:
        # restartPolicy for the Job. Can either be OnFailure or Never.
        restartPolicy: OnFailure
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 10Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 10m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 30Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 29m
        # backoffLimit defines the Kubernetes Job backoff failure policy. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy
        backoffLimit: 2
        # parallelism defines how many Pods of a Job should run in parallel. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs
        parallelism: 1
        # completions defines how many Pods of a Job should successfully complete. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job
        completions: 1
      # createInstanceServices is specified if a service should automatically be
      # created for each broker pod
      createInstanceServices: true
      instanceService:
        # name is the description of the instance service
        name: akri-debug-echo-foo-instance-service
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 6052
        # targetPort is the service targetPort of the instance service
        targetPort: 6052
        # protocol is the service protocol of the instance service
        protocol: TCP
      # createConfigurationService is specified if a single service should automatically be
      # created for all broker pods of a Configuration
      createConfigurationService: true
      configurationService:
        # name is the description of the configuration service
        name: akri-debug-echo-foo-configuration-service
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 6052
        # targetPort is the service targetPort of the instance service
        targetPort: 6052
        # protocol is the service protocol of the instance service
        protocol: TCP
    # discovery defines a set of values for a debugEcho discovery handler DaemonSet
    discovery:
      # enabled defines whether discovery handler pods will be deployed in a slim Agent scenario
      enabled: false
      image:
        # repository is the container reference
        repository: ghcr.io/project-akri/akri/debug-echo-discovery
        # tag is the container tag
        # debug-echo-configuration.yaml will default to v(AppVersion)[-dev]
        # with `-dev` added if `useDevelopmentContainers` is specified
        tag:
        # pullPolicy is the pull policy
        pullPolicy: ""
      # useNetworkConnection specifies whether the discovery handler should make a networked connection
      # with Agents, using its pod IP address when registering
      useNetworkConnection: false
      # port specifies (when useNetworkConnection is true) the port on which the discovery handler advertises its discovery service
      port: 10000
      # nodeSelectors is the array of nodeSelectors used to target nodes for the discovery handler to run on
      # This can be set from the helm command line using `--set debugEcho.discovery.nodeSelectors.label="value"`
      nodeSelectors: {}
      resources:
        # memoryRequest defines the minimum amount of RAM that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        memoryRequest: 11Mi
        # cpuRequest defines the minimum amount of CPU that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        cpuRequest: 10m
        # memoryLimit defines the maximum amount of RAM this Pod can consume.
        memoryLimit: 24Mi
        # cpuLimit defines the maximum amount of CPU this Pod can consume.
        cpuLimit: 26m

  onvif:
    configuration:
      # enabled defines whether to load a onvif configuration
      enabled: false
      # name is the Kubernetes resource name that will be created for this
      # onvif configuration
      name: akri-onvif
      # brokerProperties is a map of properties that will be passed to any instances
      # created as a result of applying this onvif configuration
      brokerProperties: {}
      discoveryDetails:
        ipAddresses:
          action: Exclude
          items: []
        macAddresses:
          action: Exclude
          items: []
        scopes:
          action: Exclude
          items: []
        uuids:
          action: Exclude
          items: []
        discoveryTimeoutSeconds: 1
      # discoveryProperties is a map of properties fthat will be passed to discovery handler,
      # the properties can be direct specified or read from Secret or ConfigMap
      discoveryProperties:
      # capacity is the capacity for any instances created as a result of
      # applying this onvif configuration
      capacity: 1
      brokerPod:
        image:
          # repository is the onvif broker container reference
          repository:
          # tag is the onvif broker image tag
          tag: latest
          # pullPolicy is the Akri onvif broker pull policy
          pullPolicy: ""
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 98Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 134m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 400Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 2800m
      brokerJob:
        # container used by onvif
        image:
          # repository is the onvif broker container reference
          repository:
          # tag is the onvif broker image tag
          tag: latest
          # pullPolicy is the onvif pull policy
          pullPolicy: ""
        # command to be executed in the Pod. An array of arguments. Can be set like:
        # --set onvif.configuration.brokerJob.command[0]="sh" \
        # --set onvif.configuration.brokerJob.command[1]="-c" \
        # --set onvif.configuration.brokerJob.command[2]="echo 'Hello World'"
        command:
        # restartPolicy for the Job. Can either be OnFailure or Never.
        restartPolicy: OnFailure
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 98Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 134m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 400Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 2800m
        # backoffLimit defines the Kubernetes Job backoff failure policy. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy
        backoffLimit: 2
        # parallelism defines how many Pods of a Job should run in parallel. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs
        parallelism: 1
        # completions defines how many Pods of a Job should successfully complete. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job
        completions: 1
      # createInstanceServices is specified if a service should automatically be
      # created for each broker pod
      createInstanceServices: true
      instanceService:
        # name is the description of the instance service
        name: akri-onvif-instance-service
        # type is the service type of the instance service
        type: ClusterIP
        # portName is the name of the port
        portName: grpc
        # port is the service port of the instance service
        port: 80
        # targetPort is the service targetPort of the instance service
        targetPort: 8083
        # protocol is the service protocol of the instance service
        protocol: TCP
      # createConfigurationService is specified if a single service should automatically be
      # created for all broker pods of a Configuration
      createConfigurationService: true
      configurationService:
        # name is the description of the configuration service
        name: akri-onvif-configuration-service
        # type is the service type of the instance service
        type: ClusterIP
        # portName is the name of the port
        portName: grpc
        # port is the service port of the instance service
        port: 80
        # targetPort is the service targetPort of the instance service
        targetPort: 8083
        # protocol is the service protocol of the instance service
        protocol: TCP
      # discovery defines a set of values for a onvif discovery handler DaemonSet
    discovery:
      # enabled defines whether discovery handler pods will be deployed in a slim Agent scenario
      enabled: false
      image:
        # repository is the container reference
        repository: ghcr.io/project-akri/akri/onvif-discovery
        # tag is the container tag
        # onvif-configuration.yaml will default to v(AppVersion)[-dev]
        # with `-dev` added if `useDevelopmentContainers` is specified
        tag:
        # pullPolicy is the pull policy
        pullPolicy: ""
      # useNetworkConnection specifies whether the discovery handler should make a networked connection
      # with Agents, using its pod IP address when registering
      useNetworkConnection: false
      # port specifies (when useNetworkConnection is true) the port on which the discovery handler advertises its discovery service
      port: 10000
      # nodeSelectors is the array of nodeSelectors used to target nodes for the discovery handler to run on
      # This can be set from the helm command line using `--set onvif.discovery.nodeSelectors.label="value"`
      nodeSelectors: {}
      resources:
        # memoryRequest defines the minimum amount of RAM that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        memoryRequest: 11Mi
        # cpuRequest defines the minimum amount of CPU that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        cpuRequest: 10m
        # memoryLimit defines the maximum amount of RAM this Pod can consume.
        memoryLimit: 24Mi
        # cpuLimit defines the maximum amount of CPU this Pod can consume.
        cpuLimit: 24m

  opcua:
    configuration:
      # enabled defines whether to load an OPC UA configuration
      enabled: false
      # name is the Kubernetes resource name that will be created for this
      # OPC UA configuration
      name: akri-opcua
      # brokerProperties is a map of properties that will be passed to any instances
      # created as a result of applying this OPC UA configuration
      brokerProperties: {}
      discoveryDetails:
        # discoveryUrls is a list of DiscoveryUrls for OPC UA servers
        discoveryUrls:
        - "opc.tcp://localhost:4840/"
        # applicationNames is a filter applied to the discovered OPC UA servers to either exclusively
        # include or exclude servers with application names in the applicationNames list.
        applicationNames:
          action: Exclude
          items: []
      # mountCertificates determines whether to mount into the broker pods k8s Secrets
      # containing OPC UA client credentials for connecting to OPC UA severs with the
      # same signing certificate authority.
      # If set to false, the brokers will attempt to make an insecure connection with the servers.
      mountCertificates: false
      # capacity is the capacity for any instances created as a result of
      # applying this OPC UA configuration
      capacity: 1
      brokerPod:
        image:
          # repository is the OPC UA broker container reference
          repository:
          # tag is the OPC UA broker image tag
          tag: latest
          # pullPolicy is the OPC UA broker pull policy
          pullPolicy: ""
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 76Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 9m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 200Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 30m
      brokerJob:
        # container used by opcua
        image:
          # repository is the opcua broker container reference
          repository:
          # tag is the opcua broker image tag
          tag: latest
          # pullPolicy is the opcua pull policy
          pullPolicy: ""
        # command to be executed in the Pod. An array of arguments. Can be set like:
        # --set opcua.configuration.brokerJob.command[0]="sh" \
        # --set opcua.configuration.brokerJob.command[1]="-c" \
        # --set opcua.configuration.brokerJob.command[2]="echo 'Hello World'"
        command:
        # restartPolicy for the Job. Can either be OnFailure or Never.
        restartPolicy: OnFailure
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 76Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 9m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 200Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 30m
        # backoffLimit defines the Kubernetes Job backoff failure policy. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy
        backoffLimit: 2
        # parallelism defines how many Pods of a Job should run in parallel. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs
        parallelism: 1
        # completions defines how many Pods of a Job should successfully complete. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job
        completions: 1
      # createInstanceServices is specified if a service should automatically be
      # created for each broker pod
      createInstanceServices: true
      instanceService:
        # name is the description of the instance service
        name: akri-opcua-instance-service
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 80
        # targetPort is the service targetPort of the instance service
        targetPort: 8083
        # protocol is the service protocol of the instance service
        protocol: TCP
      # createConfigurationService is specified if a single service should automatically be
      # created for all broker pods of a Configuration
      createConfigurationService: true
      configurationService:
        # name is the description of the configuration service
        name: akri-opcua-configuration-service
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 80
        # targetPort is the service targetPort of the instance service
        targetPort: 8083
        # protocol is the service protocol of the instance service
        protocol: TCP
    # discovery defines a set of values for a opcua discovery handler DaemonSet
    discovery:
      # enabled defines whether discovery handler pods will be deployed in a slim Agent scenario
      enabled: false
      image:
        # repository is the container reference
        repository: ghcr.io/project-akri/akri/opcua-discovery
        # tag is the container tag
        # opcua-configuration.yaml will default to v(AppVersion)[-dev]
        # with `-dev` added if `useDevelopmentContainers` is specified
        tag:
        # pullPolicy is the pull policy
        pullPolicy: ""
      # useNetworkConnection specifies whether the discovery handler should make a networked connection
      # with Agents, using its pod IP address when registering
      useNetworkConnection: false
      # port specifies (when useNetworkConnection is true) the port on which the discovery handler advertises its discovery service
      port: 10000
      # nodeSelectors is the array of nodeSelectors used to target nodes for the discovery handler to run on
      # This can be set from the helm command line using `--set opcua.discovery.nodeSelectors.label="value"`
      nodeSelectors: {}
      resources:
        # memoryRequest defines the minimum amount of RAM that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        memoryRequest: 11Mi
        # cpuRequest defines the minimum amount of CPU that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        cpuRequest: 10m
        # memoryLimit defines the maximum amount of RAM this Pod can consume.
        memoryLimit: 24Mi
        # cpuLimit defines the maximum amount of CPU this Pod can consume.
        cpuLimit: 24m

  udev:
    configuration:
      # enabled defines whether to load a udev configuration
      enabled: false
      # name is the Kubernetes resource name that will be created for this
      # udev configuration
      name: akri-udev
      # brokerProperties is a map of properties that will be passed to any instances
      # created as a result of applying this udev configuration
      brokerProperties: {}
      discoveryDetails:
        # groupRecursive defines whether to group discovered parent/children under the same instance
        groupRecursive: false
        # udevRules is the list of udev rules used to find instances created as a result of
        # applying this udev configuration
        udevRules:
      # capacity is the capacity for any instances created as a result of
      # applying this udev configuration
      capacity: 1
      brokerPod:
        image:
          # repository is the udev broker container reference
          repository:
          # tag is the udev broker image tag
          tag: latest
          # pullPolicy is the udev broker pull policy
          pullPolicy: ""
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 10Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 10m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 30Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 29m
        securityContext: {}
      brokerJob:
        # container used by udev
        image:
          # repository is the udev broker container reference
          repository:
          # tag is the udev broker image tag
          tag: latest
          # pullPolicy is the udev pull policy
          pullPolicy: ""
        # command to be executed in the Pod. An array of arguments. Can be set like:
        # --set udev.configuration.brokerJob.command[0]="sh" \
        # --set udev.configuration.brokerJob.command[1]="-c" \
        # --set udev.configuration.brokerJob.command[2]="echo 'Hello World'"
        command:
        # restartPolicy for the Job. Can either be OnFailure or Never.
        restartPolicy: OnFailure
        resources:
          # memoryRequest defines the minimum amount of RAM that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          memoryRequest: 10Mi
          # cpuRequest defines the minimum amount of CPU that must be available to this Pod
          # for it to be scheduled by the Kubernetes Scheduler
          cpuRequest: 10m
          # memoryLimit defines the maximum amount of RAM this Pod can consume.
          memoryLimit: 30Mi
          # cpuLimit defines the maximum amount of CPU this Pod can consume.
          cpuLimit: 29m
        # backoffLimit defines the Kubernetes Job backoff failure policy. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-backoff-failure-policy
        backoffLimit: 2
        # parallelism defines how many Pods of a Job should run in parallel. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job/#parallel-jobs
        parallelism: 1
        # completions defines how many Pods of a Job should successfully complete. More info:
        # https://kubernetes.io/docs/concepts/workloads/controllers/job
        completions: 1
      # createInstanceServices is specified if a service should automatically be
      # created for each broker pod
      createInstanceServices: true
      instanceService:
        # portName is the name of the port
        portName: grpc
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 80
        # targetPort is the service targetPort of the instance service
        targetPort: 8083
        # protocol is the service protocol of the instance service
        protocol: TCP
      # createConfigurationService is specified if a single service should automatically be
      # created for all broker pods of a Configuration
      createConfigurationService: true
      configurationService:
        # portName is the name of the port
        portName: grpc
        # type is the service type of the instance service
        type: ClusterIP
        # port is the service port of the instance service
        port: 80
        # targetPort is the service targetPort of the instance service
        targetPort: 8083
        # protocol is the service protocol of the instance service
        protocol: TCP
    # discovery defines a set of values for a udev discovery handler DaemonSet
    discovery:
      # enabled defines whether discovery handler pods will be deployed in a slim Agent scenario
      enabled: false
      image:
        # repository is the container reference
        repository: ghcr.io/project-akri/akri/udev-discovery
        # tag is the container tag
        # udev-configuration.yaml will default to v(AppVersion)[-dev]
        # with `-dev` added if `useDevelopmentContainers` is specified
        tag:
        # pullPolicy is the pull policy
        pullPolicy: ""
      # useNetworkConnection specifies whether the discovery handler should make a networked connection
      # with Agents, using its pod IP address when registering
      useNetworkConnection: false
      # port specifies (when useNetworkConnection is true) the port on which the discovery handler advertises its discovery service
      port: 10000
      # nodeSelectors is the array of nodeSelectors used to target nodes for the discovery handler to run on
      # This can be set from the helm command line using `--set udev.discovery.nodeSelectors.label="value"`
      nodeSelectors: {}
      host:
        # udev is the node path of udev, usually at `/run/udev`
        udev: /run/udev
      resources:
        # memoryRequest defines the minimum amount of RAM that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        memoryRequest: 11Mi
        # cpuRequest defines the minimum amount of CPU that must be available to this Pod
        # for it to be scheduled by the Kubernetes Scheduler
        cpuRequest: 10m
        # memoryLimit defines the maximum amount of RAM this Pod can consume.
        memoryLimit: 24Mi
        # cpuLimit defines the maximum amount of CPU this Pod can consume.
        cpuLimit: 24m

  # Admission Controllers (Webhooks)
  webhookConfiguration:
    # enabled defines whether to apply the Akri Admission Controller (Webhook) for Akri Configurations
    enabled: true
    # name of the webhook
    name: akri-webhook-configuration
    # base64-encoded CA certificate (PEM) used by Kubernetes to validate the Webhook's certificate, if
    # unset, will generate a self-signed certificate valid for 100y
    caBundle: null
    image:
      # repository is the Akri Webhook for Configurations image reference
      repository: ghcr.io/project-akri/akri/webhook-configuration
      # tag is the container tag
      # webhook-configuration.yaml will default to v(AppVersion)[-dev]
      # with `-dev` added if `useDevelopmentContainers` is specified
      tag:
      # pullPolicy is the Akri Webhook pull policy
      pullPolicy: Always
    certImage:
      # reference is the webhook-certgen image reference
      reference: registry.k8s.io/ingress-nginx/kube-webhook-certgen
      # tag is the webhook-certgen image tag
      tag: v1.1.1
      # pullPolicy is the webhook-certgen pull policy
      pullPolicy: IfNotPresent
    # onlyOnControlPlane dictates whether the Akri Webhook will only run on nodes with
    # the label with (key, value) of ("node-role.kubernetes.io/master", "")
    onlyOnControlPlane: false
    # allowOnControlPlane dictates whether a toleration will be added to allow to Akri Webhook
    # to run on the control plane node
    allowOnControlPlane: true
    # nodeSelectors is the array of nodeSelectors used to target nodes for the Akri Webhook to run on
    # This can be set from the helm command line using `--set webhookConfiguration.nodeSelectors.label="value"`
    nodeSelectors: {}
    resources:
      # memoryRequest defines the minimum amount of RAM that must be available to this Pod
      # for it to be scheduled by the Kubernetes Scheduler
      memoryRequest: 100Mi
      # cpuRequest defines the minimum amount of CPU that must be available to this Pod
      # for it to be scheduled by the Kubernetes Scheduler
      cpuRequest: 15m
      # memoryLimit defines the maximum amount of RAM this Pod can consume.
      memoryLimit: 100Mi
      # cpuLimit defines the maximum amount of CPU this Pod can consume.
      cpuLimit: 26m
  ```

</details>  

#### 3. Install akri

For me, I will change some values, so my installation looks like this:

```shell
helm install akri akri-helm-charts/akri \
  --set useLatestContainers=true \
  --set-string agent.nodeSelectors.worker="true" `# we need to use --set-string here to make "true" (a boolean value) work as a string` \
  --set-string webhookConfiguration.nodeSelectors.worker="true" \
  --set udev.discovery.enabled=true `# enable the udev discovery handler` \
  --set-string udev.discovery.nodeSelectors.worker="true" `# does not work currently, see [Issue 732](https://github.com/project-akri/akri/issues/732)`


```

After the installation akri will report this message:

```shell
NAME: akri
LAST DEPLOYED: Thu Jan  2 19:22:45 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the Akri Controller:
  kubectl get -o wide pods | grep controller
2. Get the Akri Agent(s):
  kubectl get -o wide pods | grep agent
3. Get the Akri Configuration(s):
  kubectl get -o wide akric
```

Executing the above commands returns some details about the deployment:

```shell
ubuntu@rke2-admin:~$ kubectl get -o wide pods | grep controller
akri-controller-deployment-5c55cdd68d-mtr85   1/1     Running   0          106s   10.42.3.224   rke2-04   <none>           <none>
ubuntu@rke2-admin:~$ kubectl get -o wide pods | grep agent
akri-agent-daemonset-7vtq5                    1/1     Running   0          112s   10.42.4.213   rke2-05   <none>           <none>
akri-agent-daemonset-tsk94                    1/1     Running   0          112s   10.42.3.223   rke2-04   <none>           <none>
ubuntu@rke2-admin:~$ kubectl get -o wide akric
No resources found in default namespace.
```

### Step 2: Identify your USB device

Connect to your kubernetes node, where your USB device is connected to. In my case I passed the USB drive in proxmox to the VM. `lsusb' lists the USB devices:

```shell
ubuntu@rke2-04:~$ lsusb
Bus 001 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 002: ID 0627:0001 Adomax Technology Co., Ltd QEMU Tablet
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 005 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 006 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 007 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 008 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
Bus 009 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 010 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 010 Device 002: ID 1e91:de2c Other World Computing Mercury Pro Optical
```

My device is:  
**Bus 010 Device 002: ID 1e91:de2c Other World Computing Mercury Pro Optical**

Next we use `udevadm` to get more details to our device. In general the syntax is:  
`udevadm info --attribute-walk --path=$(udevadm info --query=path /dev/bus/usb/<BUS>/<DEVICE>)`  
So in my case `BUS=010` and `Device=002`. This will get us a tremendous amount of information.

```shell
ubuntu@rke2-04:~$ udevadm info --attribute-walk --path=$(udevadm info --query=path /dev/bus/usb/010/002)

Udevadm info starts with the device specified by the devpath and then
walks up the chain of parent devices. It prints for every device
found, all possible attributes in the udev rules key format.
A rule to match, can be composed by the attributes of the device
and the attributes from one single parent device.

  looking at device '/devices/pci0000:00/0000:00:1e.0/0000:05:02.0/0000:07:1b.0/usb10/10-1':
    KERNEL=="10-1"
    SUBSYSTEM=="usb"
    DRIVER=="usb"
    ATTR{authorized}=="1"
    ATTR{avoid_reset_quirk}=="0"
    ATTR{bConfigurationValue}=="1"
    ATTR{bDeviceClass}=="00"
    ATTR{bDeviceProtocol}=="00"
    ATTR{bDeviceSubClass}=="00"
    ATTR{bMaxPacketSize0}=="9"
    ATTR{bMaxPower}=="0mA"
    ATTR{bNumConfigurations}=="1"
    ATTR{bNumInterfaces}==" 1"
    ATTR{bcdDevice}=="0100"
    ATTR{bmAttributes}=="c0"
    ATTR{busnum}=="10"
    ATTR{configuration}==""
    ATTR{devnum}=="2"
    ATTR{devpath}=="1"
    ATTR{idProduct}=="de2c"
    ATTR{idVendor}=="1e91"
    ATTR{ltm_capable}=="no"
    ATTR{manufacturer}=="Other World Computing"
    ATTR{maxchild}=="0"
    ATTR{power/active_duration}=="73360881"
    ATTR{power/async}=="enabled"
    ATTR{power/autosuspend}=="2"
    ATTR{power/autosuspend_delay_ms}=="2000"
    ATTR{power/connected_duration}=="73360881"
    ATTR{power/control}=="on"
    ATTR{power/level}=="on"
    ATTR{power/persist}=="1"
    ATTR{power/runtime_active_kids}=="1"
    ATTR{power/runtime_active_time}=="73360627"
    ATTR{power/runtime_enabled}=="forbidden"
    ATTR{power/runtime_status}=="active"
    ATTR{power/runtime_suspended_time}=="0"
    ATTR{power/runtime_usage}=="1"
    ATTR{product}=="Mercury Pro Optical"
    ATTR{quirks}=="0x0"
    ATTR{removable}=="unknown"
    ATTR{remove}=="(not readable)"
    ATTR{rx_lanes}=="1"
    ATTR{serial}=="002933017150"
    ATTR{speed}=="5000"
    ATTR{tx_lanes}=="1"
    ATTR{urbnum}=="3036532"
    ATTR{version}==" 3.00"

    # A very long list with all parent devices will continue here. Let's focus on the above lines
  
```

When configuring akri we need to tell it which devices it should take into consideration. To do that we will use the following two attributes of our USB device:

* `ATTR{idVendor}=="1e91"` and
* `ATTR{idProduct}=="de2c"`

You can basically use any of the above attributes.

### Step 3: Create and apply a akri udev configuration

To generate a configuration for akri we can follow the [official documentation](https://docs.akri.sh/user-guide/customizing-an-akri-installation#generating-modifying-and-applying-a-configuration). When it comes to udev rules more detailed settings are explained [here](https://docs.akri.sh/discovery-handlers/udev#discovery-handler-discovery-details-settings). Basically you enable the udev configuration and specify a udev rule for your device. In my case I created the following configuration and saved it as _configuration.yaml_:

```yaml
apiVersion: akri.sh/v0
kind: Configuration
metadata:
  name: akri-dvddrive
spec:
  capacity: 1
  discoveryHandler:
    discoveryDetails: |
      groupRecursive: true # Recommended unless using very exact udev rules
      udevRules:
      - ATTRS{idVendor}=="1e91", ATTRS{idProduct}=="de2c"
    name: udev
```

> Note that you have to adjust the values for _idVendor_ and _idProduct_.

To apply the configuration use the following command:

```shell
kubectl apply -f Homelab/Kubernetes/USB\ Passthrough/configuration.yaml
```

To check your configuration simply use `kubectl get -o wide akric` which should list your configuration:

```shell
NAME            CAPACITY   AGE
akri-dvddrive   1          3m14s
```

Right after deploying the configuration you should see an akri instance listing which of your nodes fullfills the requirements, meaning where the usb device is detected. To see that use `kubectl describe akrii`:

```yaml
Name:         akri-dvddrive-0626c2
Namespace:    default
Labels:       <none>
Annotations:  <none>
API Version:  akri.sh/v0
Kind:         Instance
Metadata:
  Creation Timestamp:  2025-01-03T13:53:50Z
  Finalizers:
    rke2-04
  Generation:  22
  Owner References:
    API Version:     akri.sh/v0
    Controller:      true
    Kind:            Configuration
    Name:            akri-dvddrive
    UID:             24922887-6727-4593-ae87-5e95b34fbb46
  Resource Version:  7108165
  UID:               eaf9e8be-e154-4cc2-96db-7e0b179bd7da
Spec:
  Broker Properties:
    UDEV_DEVNODE_3:    /dev/bsg/7:0:0:0
    UDEV_DEVNODE_5:    /dev/sr1
    UDEV_DEVNODE_7:    /dev/sg2
    UDEV_DEVNODE_8:    /dev/bus/usb/010/002
    UDEV_DEVPATH:      /devices/pci0000:00/0000:00:1e.0/0000:05:02.0/0000:07:1b.0/usb10/10-1
  Capacity:            1
  Cdi Name:            akri.sh/akri-dvddrive=0626c2
  Configuration Name:  akri-dvddrive
  Device Usage:
  Nodes:
    rke2-04 # <<<<<<<<<<<<<<<<<<<< this is the node with the usb drive
  Shared:  false
Events:    <none>
```

Take a look at the `brokerProperties` fields. Akri automatically detects a few different paths/devices that are connected to the udev query. All of these will be visible inside the pods using this resource.

### Step 4: Using the akri device in a pod

To use the detected usb device simply adjust the `resources` part of you deployment:

```yaml
resources:
    limits:
      akri.sh/akri-dvddrive: "1"
    requests:
      akri.sh/akri-dvddrive: "1"
```
