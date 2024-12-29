Shutting down an RKE2 (Rancher Kubernetes Engine 2) cluster properly to perform maintenance on the physical machine involves a systematic process to ensure minimal disruption and data integrity. Since you are using Longhorn for storage, extra care must be taken to avoid data corruption.

Here is the step-by-step procedure:

# Prepare for Shutdown
* **Verify the Cluster State**  
    Ensure the cluster is healthy before shutting it down. Use the following commands to check the status:

    ```bash
    kubectl get nodes
    kubectl get pods -A
    ```

* **Backup Important Data**
    * Backup your Kubernetes configuration (~/.kube/config).
    * Backup critical application data and Longhorn volumes.
    * Take a snapshot of your Longhorn volumes if necessary (Longhorn UI or kubectl).


* **Drain the agent Nodes**
    ```shell
    kubectl drain <agent-node> --ignore-daemonsets --delete-emptydir-data
    ```
    Repeat for each agent node to safely evict workloads.

* **Scale Down Critical Workloads (Optional)**:  
    Scale down stateful workloads that heavily use Longhorn volumes to minimize risks of data corruption.

#  Shutdown Sequence
* **Stop Agent Nodes First**
    On all agent nodes, stop the RKE2 service:

    ```shell
    systemctl stop rke2-agent
    ```
    Shutdown the node.

* **Stop control plane nodes**
    On all control plane nodes, stop the RKE2 service:

    ```shell
    systemctl stop rke2-server
    ```

* **Stop Longhorn Components**  
    Longhorn manages your data storage and should be gracefully shut down after stopping the cluster. SSH into each Longhorn node and stop the longhorn-manager service:

    ```shell
    systemctl stop longhorn-manager
    ```

* **Shutdown Physical Machine**  
    Once all components are stopped, you can safely shut down the physical machine.

# Restart After Maintenance
* **Power On the Physical Machine**  
    Once maintenance is complete, power on the machine.

* **Start RKE2 Services**  
    On each node, start the RKE2 and Longhorn services in the following order:

    1. Start RKE2 on the control plane nodes:
        ```shell
        systemctl start rke2-server
        ```
    2. Start RKE2 on the agent nodes:
        ```shell
        systemctl start rke2-agent
        ```
    3. Start Longhorn on its respective nodes:
        ```shell
        systemctl start longhorn-manager
        ```
* **Verify Cluster Health**  
    Check the cluster state after it has restarted
    ```shell
    kubectl get nodes
    kubectl get pods -A
    ```
    Verify that all nodes and workloads are functioning correctly.

# Repopulate Workloads (If Scaled Down)
If you scaled down workloads before the shutdown, scale them back up using:

```shell
kubectl scale deployment <deployment-name> --replicas=<desired-replica-count>
```
By following these steps, you minimize risks of data corruption and ensure a smooth shutdown and restart process for your RKE2 cluster.