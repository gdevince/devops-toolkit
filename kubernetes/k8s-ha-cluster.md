> **Nota** — Documentazione tecnica redatta durante un tirocinio (lab on-prem, Ago–Set 2022) per la messa in opera di un cluster Kubernetes HA con etcd esterno su VM Hyper-V.
> Tutti gli IP, MAC address, hostname di dominio, password, token e hash presenti sono **placeholder** o valori di un ambiente di laboratorio effimero ormai dismesso: non corrispondono ad alcuna infrastruttura reale. Sostituirli con i propri valori prima dell'uso.

# `0` INDEX

- [`0` INDEX](#0-index)
- [`A` K8s HA Cluster with External etcd](#a-k8s-ha-cluster-with-external-etcd)
  - [`A1` Host data](#a1-host-data)
  - [`A2` VMs data](#a2-vms-data)
  - [`A3` Dashboards data](#a3-dashboards-data)
  - [`A4` HYPER-V Checkpoint data](#a4-hyper-v-checkpoint-data)
  - [`A5` PuTTY](#a5-putty)
- [`B` CONFIGURAZIONE BASE DELLE VM](#b-configurazione-base-delle-vm)
  - [`B1` Install Windows Server 2022 Datacenter on host](#b1-install-windows-server-2022-datacenter-on-host)
  - [`B2` Enable Remote Desktop](#b2-enable-remote-desktop)
  - [`B3` Enable Hyper-V in Windows Features](#b3-enable-hyper-v-in-windows-features)
  - [`B4` Download ISO](#b4-download-iso)
  - [`B5` Creare lo Switch adatto alle VMs](#b5-creare-lo-switch-adatto-alle-vms)
  - [`B6` Creare la VM](#b6-creare-la-vm)
  - [`B7` Ubuntu first configs](#b7-ubuntu-first-configs)
    - [`B7.1` TimeZone Change](#b71-timezone-change)
    - [`B7.2` Netplan Configuration](#b72-netplan-configuration)
    - [`B7.3` Export/Import Option delle VMs](#b73-exportimport-option-delle-vms)
    - [`B10.1` Move VMs from HOST0 to HOST1](#b101-move-vms-from-host0-to-host1)
  - [`B11` Resolve VM Hostname with DNS Server](#b11-resolve-vm-hostname-with-dns-server)
  - [`B12` Disable Swap](#b12-disable-swap)
  - [`B13` Fornire i MAC Address ad un SysAdmin per uscire in rete](#b13-fornire-i-mac-address-ad-un-sysadmin-per-uscire-in-rete)
  - [`B14` Ubuntu Server FIREWALL](#b14-ubuntu-server-firewall)
- [`C` CONFIGURAZIONE DIPENDENZE K8S](#c-configurazione-dipendenze-k8s)
  - [`C1` Install containerd, systemd or runc, CNI](#c1-install-containerd-systemd-or-runc-cni)
    - [`C1.1` config.toml](#c11-configtoml)
  - [`C2` Forwarding IPV4 and letting iptables see bridged traffic](#c2-forwarding-ipv4-and-letting-iptables-see-bridged-traffic)
  - [`C3` Install kubeadm, kubectl, kubelet](#c3-install-kubeadm-kubectl-kubelet)
    - [`C3.1` kubeadm Versioning](#c31-kubeadm-versioning)
    - [`C3.2` kubeadm Uninstall](#c32-kubeadm-uninstall)
- [`D` LOAD BALANCER](#d-load-balancer)
  - [`D1` Install keepalived](#d1-install-keepalived)
  - [`D2` Install haproxy](#d2-install-haproxy)
  - [`D3` Enable keepalived and haproxy](#d3-enable-keepalived-and-haproxy)
  - [`D4` Repeat](#d4-repeat)
  - [`D5` Add first control-plane node to load balancer](#d5-add-first-control-plane-node-to-load-balancer)
- [`E` ETCD (External type)](#e-etcd-external-type)
  - [`E1` Configure External type etcd nodes](#e1-configure-external-type-etcd-nodes)
  - [`E2` Generate kubeadm config file for each etcd host](#e2-generate-kubeadm-config-file-for-each-etcd-host)
  - [`E3` Generate certificate authority](#e3-generate-certificate-authority)
  - [`E4` Create certificate for each member](#e4-create-certificate-for-each-member)
  - [`E5` Copy certificates and kubeadm configs](#e5-copy-certificates-and-kubeadm-configs)
  - [`E6` Ensure all file exists](#e6-ensure-all-file-exists)
  - [`E7` Create static POD manifests](#e7-create-static-pod-manifests)
- [`F` SSH](#f-ssh)
- [`G` K8S](#g-k8s)
  - [`G1` Init del 1° Master control-plane](#g1-init-del-1-master-control-plane)
  - [`G2` Move control-plane certs](#g2-move-control-plane-certs)
  - [`G3` CNI install](#g3-cni-install)
  - [`G4` Master control-plane join](#g4-master-control-plane-join)
  - [`G5` Worker Join](#g5-worker-join)
- [`H` ADDONS](#h-addons)
  - [`H1` metric-server](#h1-metric-server)
- [`L` PLUGINS](#l-plugins)
  - [`L1` Install KUBE-PROMETHEUS-STACK](#l1-install-kube-prometheus-stack)
    - [`L1.1` Port-forward (Internally Access to Prom and Grafana Dashboard)](#l11-port-forward-internally-access-to-prom-and-grafana-dashboard)
    - [`L1.2` NodePort Services Expose (Externally Access to Prom and Grafana Dashboard)](#l12-nodeport-services-expose-externally-access-to-prom-and-grafana-dashboard)
    - [`L1.3` Dashboards Connect](#l13-dashboards-connect)
    - [`L1.4` if Prometheus Dashboard TARGETS are down](#l14-if-prometheus-dashboard-targets-are-down)
      - [`L1.4.1` kube-proxy Prometheus target down](#l141-kube-proxy-prometheus-target-down)
      - [`L1.4.2` kube-scheduler Prometheus target down](#l142-kube-scheduler-prometheus-target-down)
      - [`L1.4.3` kube-state-metrics Prometheus target down](#l143-kube-state-metrics-prometheus-target-down)
    - [`L1.5` Uninstall kube-prometheus-stack](#l15-uninstall-kube-prometheus-stack)
  - [`L2` Install VELERO (Cluster Backup)](#l2-install-velero-cluster-backup)
    - [`L2.1` Install Velero CLI](#l21-install-velero-cli)
    - [`L2.2` Install and Configure Server components](#l22-install-and-configure-server-components)
- [`M` Azure Pipeline Build-Agent Container](#m-azure-pipeline-build-agent-container)
  - [`M1` Testing buildagent on Azure DevOps Pipeline](#m1-testing-buildagent-on-azure-devops-pipeline)
    - [`M1.1` Create a Pipeline](#m11-create-a-pipeline)
    - [`M1.2` Launch a Pipeline](#m12-launch-a-pipeline)

<!-- pagebreak -->



# `A` K8s HA Cluster with External etcd

Nodi Kubernetes (Ubuntu VMs in Hyper-V) condivisi tra due Host (Windows Server 2022 Datacenter).
Da migrare in seguito, quindi da non applicare:
- `Failover Clustering`
- - `Live Migration`
Spostate a mano con Export/Import, attenzione a corruzione dei file e impostazioni Switch...


## `A1` Host data
| HOST name       | HOST IP        | HOST usr      | HOST pwd       |
| :---            | :---:          | :---:         | :---:          | 
| K8S-NODE0       |`10.0.0.10` | Administrator | <host-password> |
| K8S-NODE1       | `10.0.0.11`  | Administrator | <host-password>     |


## `A2` VMs data
VM domain                          | LoadBalancers Virtual IP  | k8S POD Network CIDR |
| :---                             | :---:                     | :---:
| collaboration.example.internal | `10.0.0.100`          | `172.16.0.0/12`      |

Non usare la POD Network CIDR `10.0.0.0/8` per evitare conflitti con `--service-cluster-ip-range=10.96.0.0/12`

| HOST      | VM name               | VM IP           | VM MAC            | VM usr   | VM pwd |
| :---      | :---                  | :---:           | :---:             | :---:    | ---:   |
| K8S-NODE0 | `k8s-load-balancer-0` | `10.0.0.20` | <MAC_ADDR> | `master` | master |
| K8S-NODE1 | `k8s-load-balancer-1` | `10.0.0.21` | <MAC_ADDR> | `master` | master |
| K8S-NODE0 | `k8s-master-0`        | `10.0.0.30` | <MAC_ADDR> | `master` | master |
| K8S-NODE1 | `k8s-master-1`        | `10.0.0.31` | <MAC_ADDR> | `master` | master |
| K8S-NODE0 | `k8s-master-2`        | `10.0.0.32` | <MAC_ADDR> | `master` | master |
| K8S-NODE0 | `k8s-master-0-etcd`   | `10.0.0.40` | <MAC_ADDR> | `master` | master |
| K8S-NODE1 | `k8s-master-1-etcd`   | `10.0.0.41` | <MAC_ADDR> | `master` | master |
| K8S-NODE0 | `k8s-master-2-etcd`   | `10.0.0.42` | <MAC_ADDR> | `master` | master |
| K8S-NODE0 | `k8s-worker-0`        | `10.0.0.50` | <MAC_ADDR> | `master` | master |
| K8S-NODE1 | `k8s-worker-1`        | `10.0.0.51` | <MAC_ADDR> | `master` | master |
| K8S-NODE1 | `k8s-worker-2`        | `10.0.0.52` | <MAC_ADDR> | `master` | master |

**Allocated VMs resources**
| Load Balancer | Master   | Worker   | etcd     |
| :---:         | :---:    | :---:    | :---:    |
| 1 cpu         | 2 cpu    | 2 cpu    | 1 cpu    |
| 2048 mem      | 4096 mem | 7598 mem | 4096 mem |

## `A3` Dashboards data

| Prometheus Dashboard        | Prometheus Alertmanager    | 
| :---                        | ---:                       |
| http://10.0.0.31:31026  | http://10.0.0.32:31001 | 

| Grafana Dashboard          | Grafana usr   | Grafana pwd   |
| :---                       | :---:         | ---:          |
| http://10.0.0.31:31361 | admin         | prom-operator |

Nell'URL, posso sostituire l'IP con gli altri IP o i nomi dei master/worker, purché puntino alla porta indicata nell'URL.

## `A4` HYPER-V Checkpoint data

**ATTENZIONE:** Utilizzare un checkpoint significa inquinarlo (se posizionati su) con delle modifiche, crearne uno prima di apportarle!

| DATA       | ORA      | Descrizione                                                                                                           |
| :---       | :---:    | :---                                                                                                                  |
| 26/08/2022 | 09:27:10 | VM configurate, PRE-INIT (certificati presenti solo su master control-plane)                                          |
| 26/08/2022 | 10:25:35 | Cluster in running (TUTTI I NODI JOINATI)                                                                             |
| 26/08/2022 | 11:33:09 | checkpoint di strato (per non inquinare i checkpoint precedenti)                                                      |
| 26/08/2022 | 15:54:56 | Cluster kube-prometheus-stack, non funzionano target kube-controllermanager e kube-scheduler, fixato kube-proxy UP    |
| 27/08/2022 | 18:04:27 | Sul cluster funziona tutto: Prometheus, Graphana, Alertmanager, Lens                         |
| 01/09/2022 | 17:06:00 | Assegnaz. nuova interfaccia (vEth) alle VMs e 7598MB di RAM assegnati ai Worker. Cluster ufficalmente composto da VM che risiedono su 2 nodi Host differenti |
| 01/09/2022 | 17:08:00 | Checkpoint Layer |


## `A5` PuTTY
E' una best practice utilizzare [PuTTY](https://putty.org/) per qualsiasi operazione sulle VMs.

| return to [`A` K8s HA Cluster with External etcd](#a-k8s-ha-cluster-with-external-etcd) | return to [`0` INDEX](#0-index) |
| :---  | ---: |

---

# `B` CONFIGURAZIONE BASE DELLE VM

## `B1` Install Windows Server 2022 Datacenter on host

[Windows Server 2022 Datacenter](https://www.microsoft.com/it-it/windows-server/pricing) 

## `B2` Enable Remote Desktop

Per eseguire le operazioni in remoto dalla propria workstation.
`Settings > System > Remote Desktop` 

## `B3` Enable Hyper-V in Windows Features

[Hyper-V](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/quick-start/enable-hyper-v)

`Turn Windows features on or off: Hyper-V`
WS2022D, tuttavia, **NON** dispone di due feature in Hyper-V:

- Default Switch (vedi **punto `A5`**)
- Quick Create

## `B4` Download ISO

- [Ubuntu Server LTS](https://ubuntu.com/download/server)
- Windows Server 2022

## `B5` Creare lo Switch adatto alle VMs

di tipo `vEthExternal`

## `B6` Creare la VM

- Selezionare lo Switch creato 
- Allocare una corretta quantità di RAM
- Montare la ISO scaricata
- In `Advanced Options` dI **scheda di rete**, flaggare `Static MAC Address`. \
Quest'ultimo passaggio è molto importante per poter uscire dalla Intranet!

## `B7` Ubuntu first configs

[Ubuntu](https://ubuntu.com/tutorials/install-ubuntu-server#1-overview)

### `B7.1` TimeZone Change

```bash
sudo unlink /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Rome /etc/localtime
timedatectl
```

### `B7.2` Netplan Configuration

- Visualizzare il nome dell'interfaccia di rete da configurare (tipicamente **eth0**): `ip a`
- Aprire con un editor lo **YAML** nel path: `sudo nano /etc/netplan/*.yaml`

<details>
  <summary>Show code</summary>

```YAML
network:
  ethernets:
    eth0:
      dhcp4: false
      dhcp-identifier: mac #add this option
      addresses:
        - 10.0.0.31/23 #ip della vm
      gateway4: 10.0.0.1
      nameservers:
        search:
          - "collaboration.example.internal" #subdomain
        addresses:
          - 10.0.0.2
          - 10.0.0.3
  version: 2
```
In caso `gateway4` dia problemi (deprecato), sostituire con:
```YAML
routes:
    - to: default
      via: 10.0.0.1
```
- Prestare attenzione all'indentazione e salvare le modifiche, quindi:
```bash
sudo netplan apply
ip a
```
</details>

### `B7.3` Export/Import Option delle VMs

**Saltare questo passaggio e ritornare al punto** [`B6` Creare la VM](#b6-creare-la-vm) **se si intende ricrearle a mano!**
Attenzione alle sovrapposizioni di MAC o IP Address!

<details>
  <summary>Show</summary>

- Replicare le VM con l'opzione **Export/Import** di Hyper-V
  - `Bisogna rinominare a mano le VM e i loro Volumes!`
- **E' necessario cambiare l'** `hostname` **della nuova copia:**
```bash
  hostnamectl #visualizza hostname attuale
  hostnamectl set-hostname nomeNuovoHostname #cambia hostname
  reboot #rende effettive le modifiche
```
</details>

### `B10.1` Move VMs from HOST0 to HOST1

Nel caso in cui le VMs vengano create precedentemente su un solo host, è necessario spostarle per creare HA in modo da avere un bilanciamento.

Utilizzare il protocollo `SMB` per fare Export/Import dei relativi file della VM.

## `B11` Resolve VM Hostname with DNS Server

<details>
  <summary>Show code</summary>

Modificare il file `dhclient.conf` in `/etc/dhcp/`
```bash
send fqdn.fqdn "k8s-master-0.collaboration.example.internal";
send fqdn.encoded on;
send fqdn.server-update on;
```
Then, to release your lease with the DHCP server and get a new lease run the following commands:
```bash
sudo dhclient -r
sudo dhclient
```
Ora si potrà fare un `nslookup` dalla macchina host, o da altri host interni, alla VM:
```bash
nslookup 10.0.0.30
nslookup k8s-master-0
nslookup k8s-master-0.collaboration.example.internal
```
</details>

## `B12` Disable Swap

Commentare (`#`) la riga che monta lo swap in `/etc/fstab`, salvare e fare un reboot. \
**Non** utilizzare `sudo swapoff -a`, funziona solo per la sessione corrente.

## `B13` Fornire i MAC Address ad un SysAdmin per uscire in rete
...per prenotare un IP alla propria VM tramite MAC Address.
Le VMs devono avere IP Statici legati al loro MAC Address!
```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get dist-upgrade
apt install net-tools
```
## `B14` Ubuntu Server FIREWALL

- Se `disattivato`: OK
- Se `attivo`, abilitare:
  - porta `22` per ssh, PuTTY
  - porta `10250` per metric-server, altrimenti un nodo può risultare STATUS=UNKNOWN

| return to [`B` CONFIGURAZIONE BASE DELLE VM](#b-configurazione-base-delle-vm) | return to [`0` INDEX](#0-index) |
| :---  | ---: |

---

# `C` CONFIGURAZIONE DIPENDENZE K8S

## `C1` Install containerd, systemd or runc, CNI

[containerd](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)

Seguire gli step di **`Option 2` su GitHub** (per non avere problemi con la config manuale dei binaries e l'avvio automatico in systemd). Le dipendenze non sono fornite da containerd project ma da Docker:
```bash
sudo apt install containerd
sudo apt install runc
```

Tuttavia i `CNI Plugins` vanno installati manualmente da `Option 1` - `Step 3 su GitHub`:
  - Download [here](https://github.com/containernetworking/plugins/releases) & extract `cni-plugins-<OS>-<ARCH>-<VERSION>.tgz` in `/opt/cni/bin`
      
```bash
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz #attento al numero di versione!
./
./macvlan
./static
./vlan
./portmap
./host-local
./vrf
./bridge
./tuning
./firewall
./host-device
./sbr
./loopback
./dhcp
./ptp
./ipvlan
./bandwidth
```

### `C1.1` config.toml

- Creare `config.toml` in `/etc/containerd/`
```bash
containerd config default > /etc/containerd/config.toml
# mette un template di default nel file appena creato
```
Per usare systemd cgroup driver, entrare in `config.toml` e aggiungere `SystemdCgroup = true`
```bash
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true   #add this
```
You need CRI support enabled to use containerd with Kubernetes. Make sure that cri is not included in the `disabled_plugins` list within `/etc/containerd/config.toml`; if you made changes to that file, also restart containerd.
```bash
sudo systemctl restart containerd
```

## `C2` Forwarding IPV4 and letting iptables see bridged traffic

[IPV4](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic)

Verifica che il modulo `br_netfilter` sia stato caricato:
```bash
lsmod | grep br_netfilter
```
Per caricarlo esplicitamente:
```bash
sudo modprobe br_netfilter
```
Per far vedere correttamente il traffico bridged alla iptable di un nodo Linux verifica che `net.bridge.bridge-nf-call-iptables` è settato a `1` in sysctl config. Per esempio:
```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
```

## `C3` Install kubeadm, kubectl, kubelet

[kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) , [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)

Update apt package index and install packages needed to use Kubernetes apt repository:
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
```
Download Google Cloud public signing key:
```bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```
Add K8S apt repository:
```bash
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
Update apt package index, install kubelet, kubeadm and kubectl and pin their version:
```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

### `C3.1` kubeadm Versioning

Potrebbe capitare di voler settare una versione specifica di K8S e nel mentre esce un aggiornamento dello stesso.
In questo caso bisognerebbe specificare la versione:
- `kubelet=1.24.3-00`
- `kubeadm=1.24.3-00`
- `kubectl=1.24.3-00`

Versione multiple delle stesse dipendenze potrebbero anche già essere state scaricate, in questo caso si potrebbe controllare:
```bash
apt-cache policy | less
```
...e per evitare upgrade dei package, come da comandi sopra lanciare un `apt-mark hold`.

### `C3.2` kubeadm Uninstall

```bash
kubeadm reset
sudo apt-get purge kubeadm kubectl kubelet kubernetes-cni kube*   
sudo apt-get autoremove  
sudo rm -rf ~/.kube
```
**Ricorda:** Questi comandi non cancellano i package, ma fanno un cleaning dell'ambiente, compresa la cartella **`/etcd`** in `/etc/kubernetes/pki/` con il suo **certificato** (gli altri cert rimarranno intatti).

| return to [`C` CONFIGURAZIONE DIPENDENZE K8S](#c-configurazione-dipendenze-k8s) | return to [`0` INDEX](#0-index) |
| :---  | ---: |

---

# `D` LOAD BALANCER

Riservare **due** VMs per il Load Balancer.

## `D1` Install keepalived

- Installare keepalived
- creare `keepalived.conf` in `/etc/keepalived`

<details>
  <summary>Show code</summary>

```bash
! /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state ${STATE}
    interface ${INTERFACE}
    virtual_router_id ${ROUTER_ID}
    priority ${PRIORITY}
    authentication {
        auth_type PASS
        auth_pass ${AUTH_PASS}
    }
    virtual_ipaddress {
        ${APISERVER_VIP}
    }
    track_script {
        check_apiserver
    }
}
```
There are some placeholders in bash variable style to fill in:

- `${STATE}` is MASTER for one and BACKUP for all other hosts, hence the virtual IP will initially be assigned to the MASTER.

- `${INTERFACE}` is the network interface taking part in the negotiation of the virtual IP, e.g. eth0.

- `${ROUTER_ID}` should be the same for all keepalived cluster hosts while unique amongst all clusters in the same subnet. Many distros pre-configure its value to 51.

- `${PRIORITY}` should be higher on the control plane node than on the backups. Hence 101 and 100 respectively will suffice.

- `${AUTH_PASS}` should be the same for all keepalived cluster hosts, e.g. 42

- `${APISERVER_VIP}`is the virtual IP address negotiated between the keepalived cluster hosts.

The above keepalived configuration uses a health check script `/etc/keepalived/check_apiserver.sh` responsible for making sure that on the node holding the virtual IP the API Server is available. This script could look like this:

```bash
#!/bin/sh

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_DEST_PORT}/"
if ip addr | grep -q ${APISERVER_VIP}; then
    curl --silent --max-time 2 --insecure https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/"
fi
```

There are some placeholders in bash variable style to fill in:
- `${APISERVER_VIP}` is the virtual IP address negotiated between the keepalived cluster hosts.
- `${APISERVER_DEST_PORT}` the port through which Kubernetes will talk to the API Server.

</details>

## `D2` Install haproxy

- Installare hproxy
- Creare `haproxy.cfg` in `/etc/haproxy`

<details>
  <summary>Show code</summary>

```bash
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:${APISERVER_DEST_PORT}
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server ${HOST1_ID} $
```

There are some placeholders in bash variable style to expand:

- `${APISERVER_DEST_PORT}` the port through which Kubernetes will talk to the API Server.
- `${APISERVER_SRC_PORT}` the port used by the API Server instances.
- `${HOST1_ID}` a symbolic name for the first load-balanced API Server host.
- `${HOST1_ADDRESS}` a resolvable address (DNS name, IP address) for the first load-balanced API Server host.
- `Additional server lines` one for each load-balanced API Server host.

</details>

## `D3` Enable keepalived and haproxy

```bash
systemctl enable haproxy --now
systemctl enable keepalived --now
```

## `D4` Repeat

Ripetere i **punti** [`D1` Install keepalived](#d1-install-keepalived), [`D2` Install haproxy](#d2-install-haproxy) e [`D3` Enable keepalived and haproxy](#d3-enable-keepalived-and-haproxy) per la seconda Load Balancer VM.

**Attenzione!**
Nella seconda macchina che fa da load balancer, in `/etc/keepalived/keepalived.conf` (**punto** `D1`)
```bash
vrrp_instance VI_1 {
    state ${STATE}
```
sostituire `BACKUP` a `${STATE}` ; `MASTER` è riservato al Load Balancer principale.

[Fonte Github di 1, 2 & 3](https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing)

## `D5` Add first control-plane node to load balancer

and test the connection:
```bash
nc -v <LOAD_BALANCER_IP> <PORT>
```
A connection refused error is expected because the API server is not yet running. \
A timeout, however, means the load balancer cannot communicate with the control plane node. \
If a timeout occurs, reconfigure the load balancer to communicate with the control plane node.

Add the remaining control plane nodes to the load balancer target group.

| return to [`D` LOAD BALANCER](#d-load-balancer) | return to [`0` INDEX](#0-index) |
| :---  | ---: |

---

# `E` ETCD (External type)

Fonti: [1](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/) e [2](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/setup-ha-etcd-with-kubeadm/)

## `E1` Configure External type etcd nodes

Eseguire i seguenti comandi su tutte le VMs etcd:

```bash
cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
# Replace "systemd" with the cgroup driver of your container runtime. The default value in the kubelet is "cgroupfs".
# Replace the value of "--container-runtime-endpoint" for a different container runtime if needed.
ExecStart=/usr/bin/kubelet --address=127.0.0.1 --pod-manifest-path=/etc/kubernetes/manifests --cgroup-driver=systemd --container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock
Restart=always
EOF

systemctl daemon-reload
systemctl restart kubelet
systemctl status kubelet
```

## `E2` Generate kubeadm config file for each etcd host

**HOST0, HOST1 e HOST2 sono le 3 VMs etcd!**
Il seguente è uno script da eseguire su `HOST0`:

<details>
  <summary>Show code</summary>

```bash
# Update HOST0, HOST1 and HOST2 with the IPs of your hosts
export HOST0=10.0.0.40
export HOST1=10.0.0.41
export HOST2=10.0.0.42

# Update NAME0, NAME1 and NAME2 with the hostnames of your hosts
export NAME0="k8s-master-0-etcd"
export NAME1="k8s-master-1-etcd"
export NAME2="k8s-master-2-etcd"

# Create temp directories to store files that will end up on other hosts.
mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

HOSTS=(${HOST0} ${HOST1} ${HOST2})
NAMES=(${NAME0} ${NAME1} ${NAME2})

for i in "${!HOSTS[@]}"; do
HOST=${HOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: InitConfiguration
nodeRegistration:
    name: ${NAME}
localAPIEndpoint:
    advertiseAddress: ${HOST}
---
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: ${NAMES[0]}=https://${HOSTS[0]}:2380,${NAMES[1]}=https://${HOSTS[1]}:2380,${NAMES[2]}=https://${HOSTS[2]}:2380
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
EOF
done
```

</details>

## `E3` Generate certificate authority

If you already have a CA then the only action that is copying the CA's crt and key file to `/etc/kubernetes/pki/etcd/ca.crt` and `/etc/kubernetes/pki/etcd/ca.key`.

If you do not already have a CA then run this command on `$HOST0` (where you generated the configuration files for kubeadm).

```bash
kubeadm init phase certs etcd-ca 
```
Questo comando crea due file:
- `/etc/kubernetes/pki/etcd/ca.crt`
- `/etc/kubernetes/pki/etcd/ca.key`

## `E4` Create certificate for each member

<details>
  <summary>Show code</summary>

```bash
export HOST0=10.0.0.40
export HOST1=10.0.0.41
export HOST2=10.0.0.42

kubeadm init phase certs etcd-server --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST2}/
# cleanup non-reusable certificates
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${HOST1}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
# No need to move the certs because they are for HOST0

# clean up certs that should not be copied off this host
find /tmp/${HOST2} -name ca.key -type f -delete
find /tmp/${HOST1} -name ca.key -type f -delete
```
</details>

## `E5` Copy certificates and kubeadm configs

**da `$HOST0` a `$HOST1`:**

<details>
  <summary>Show code</summary>

```bash
USER=master
HOST=${HOST1}
scp -r /tmp/${HOST}/* ${USER}@${HOST}:
ssh ${USER}@${HOST}
USER@HOST $ sudo -Es
root@HOST $ chown -R root:root pki
```
**su `$HOST1`:**
```bash
root@HOST $ mv pki /etc/kubernetes/
```

</details>

**da `$HOST0` a `$HOST2`:**

<details>
  <summary>Show code</summary>

```bash
USER=master
HOST=${HOST2}
scp -r /tmp/${HOST}/* ${USER}@${HOST}:
ssh ${USER}@${HOST}
USER@HOST $ sudo -Es
root@HOST $ chown -R root:root pki
```
</details>

**su `$HOST2`:**
```bash
root@HOST $ mv pki /etc/kubernetes/
```

## `E6` Ensure all file exists

**su `$HOST0`:**
```bash
/tmp/${HOST0}
└── kubeadmcfg.yaml
---
/etc/kubernetes/pki
├── apiserver-etcd-client.crt
├── apiserver-etcd-client.key
└── etcd
    ├── ca.crt
    ├── ca.key
    ├── healthcheck-client.crt
    ├── healthcheck-client.key
    ├── peer.crt
    ├── peer.key
    ├── server.crt
    └── server.key
```

**su `$HOST1`:**
```bash
$HOME
└── kubeadmcfg.yaml
---
/etc/kubernetes/pki
├── apiserver-etcd-client.crt
├── apiserver-etcd-client.key
└── etcd
    ├── ca.crt
    ├── healthcheck-client.crt
    ├── healthcheck-client.key
    ├── peer.crt
    ├── peer.key
    ├── server.crt
    └── server.key
```

**su `$HOST2`:**
```bash
$HOME
└── kubeadmcfg.yaml
---
/etc/kubernetes/pki
├── apiserver-etcd-client.crt
├── apiserver-etcd-client.key
└── etcd
    ├── ca.crt
    ├── healthcheck-client.crt
    ├── healthcheck-client.key
    ├── peer.crt
    ├── peer.key
    ├── server.crt
    └── server.key
```

## `E7` Create static POD manifests

**su `$HOST0`:**
```bash
root@HOST0 $ kubeadm init phase etcd local --config=/tmp/${HOST0}/kubeadmcfg.yaml
```

**su `$HOST1`:**
```bash
root@HOST1 $ kubeadm init phase etcd local --config=$HOME/kubeadmcfg.yaml
```

**su `$HOST2`:**
```bash
root@HOST2 $ kubeadm init phase etcd local --config=$HOME/kubeadmcfg.yaml
```

| return to [`E` ETCD](#e-etcd) | return to [`0` INDEX](#0-index) |
| :--- | ---: |

---

# `F` SSH

Fonti: [1](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/#manual-certs), [2](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

**su `$HOST0` (etcd):**
```bash
eval $(ssh-agent)
ssh-keygen -t ed25519 #crea private key
ssh-add ~/.ssh/path_to_private_key #punta alla private key generata
```

| return to [`F` SSH](#f-ssh) | return to [`0` INDEX](#0-index) |
| :--- | ---: |

---

# `G` K8S

Copiare i certificati da un nodo etcd qualsiasi nel cluster al primo nodo master control-plane.

Su host etcd, sostituire `CONTROL_PLANE` con master@10.0.0.30 del primo control-plane node:
```bash
export CONTROL_PLANE="master@10.0.0.30"
scp /etc/kubernetes/pki/etcd/ca.crt "${CONTROL_PLANE}":
scp /etc/kubernetes/pki/apiserver-etcd-client.crt "${CONTROL_PLANE}":
scp /etc/kubernetes/pki/apiserver-etcd-client.key "${CONTROL_PLANE}":
```
Quindi lanciare il seguente script:
```bash
USER=master # customizable
mkdir -p /etc/kubernetes/pki/etcd
mv /home/${USER}/ca.crt /etc/kubernetes/pki/etcd/ca.crt
mv /home/${USER}/apiserver-etcd-client.crt /etc/kubernetes/pki/apiserver-etcd-client.crt
mv /home/${USER}/apiserver-etcd-client.key /etc/kubernetes/pki/apiserver-etcd-client.key
```
**NOTA:**
Un `kubeadm reset` sul primo master control-plane (**vedi** [`C3.2` kubeadm Uninstall](#c32-kubeadm-uninstall) ) comporta l'eliminazione della cartella `/etcd` in `/etc/kubernetes/pki/`. \
Per non creare manualmente la cartella o avere problemi di permessi negati, utilizzare **a prescindere** lo script sopra **sul primo master control-plane** (operazione simile avviene nel **punto** `G2`, ma mirata agli altri master control-plane).

## `G1` Init del 1° Master control-plane

Fare init del file config per mettere su il primo master control-plane:

```YAML
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: "172.16.0.0/12"
kubernetesVersion: 1.24.3
controlPlaneEndpoint: "10.0.0.100:6443" # VirtualIP
etcd:
  external:
    endpoints:
      - https://10.0.0.40:2379 # ETCD_0_IP
      - https://10.0.0.41:2379 # ETCD_1_IP 
      - https://10.0.0.42:2379 # ETCD_2_IP
    caFile: /etc/kubernetes/pki/etcd/ca.crt
    certFile: /etc/kubernetes/pki/apiserver-etcd-client.crt
    keyFile: /etc/kubernetes/pki/apiserver-etcd-client.key
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
```
**Applicare lo YAML:**
```bash
sudo kubeadm init --config kubeadm-config.yaml --upload-certs
```
Il config applicato si troverà in: `~/.kube/config`


**Output dopo l'init:**
```bash
Your Kubernetes control-plane has initialized successfully!
To start using your cluster, you need to run the following as a regular user:
# i seguenti comandi sono PERMANENTI, obbligatorio!
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
Alternatively, if you are the root user, you can run:
# il seguente comando non è permanente, sconsigliato!
  export KUBECONFIG=/etc/kubernetes/admin.conf
You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/
You can now join any number of the control-plane node running the following command on each as root: # token per gli altri control-plane
  kubeadm join 10.0.0.100:6443 --token <BOOTSTRAP_TOKEN> \
        --discovery-token-ca-cert-hash sha256:<CA_CERT_HASH> \
        --control-plane --certificate-key <CERTIFICATE_KEY>
Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.
Then you can join any number of worker nodes by running the following on each as root: # token per i worker
kubeadm join 10.0.0.100:6443 --token <BOOTSTRAP_TOKEN> \
        --discovery-token-ca-cert-hash sha256:<CA_CERT_HASH>
```

Quando il `--certificate-key` scade, per joinare altri control-plane:
```bash
sudo kubeadm init phase upload-certs --upload-certs --config kubeadm-config.yaml
```
Per stampare userName@clusterName:
```bash
kubectl config current-context
```

## `G2` Move control-plane certs

**`Dopo aver configurato SSH su tutti i nodi:`**\
Lanciare il seguente script sul master control-plane, che copia il certificato di questo control plane agli altri master control-plane.

```bash
USER=master # customizable
CONTROL_PLANE_IPS="10.0.0.31 10.0.0.32"
for host in ${CONTROL_PLANE_IPS}; do
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:etcd-ca.crt
    # Skip the next line if you are using external etcd
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:etcd-ca.key
done
```
**Su tutti gli altri control-plane master, prima di fare il join**, eseguire lo script seguente per muovere i certificati spostati prima in home, nelle folder delle altre VMs:

```bash
USER=master # customizable
mkdir -p /etc/kubernetes/pki/etcd
mv /home/${USER}/ca.crt /etc/kubernetes/pki/
mv /home/${USER}/ca.key /etc/kubernetes/pki/
mv /home/${USER}/sa.pub /etc/kubernetes/pki/
mv /home/${USER}/sa.key /etc/kubernetes/pki/
mv /home/${USER}/front-proxy-ca.crt /etc/kubernetes/pki/
mv /home/${USER}/front-proxy-ca.key /etc/kubernetes/pki/
mv /home/${USER}/etcd-ca.crt /etc/kubernetes/pki/etcd/ca.crt
# Skip the next line if you are using external etcd
mv /home/${USER}/etcd-ca.key /etc/kubernetes/pki/etcd/ca.key
```

## `G3` CNI install

La CNI scelta, [Calico](https://projectcalico.docs.tigera.io/getting-started/kubernetes/quickstart) esplicita di passare il seguente flag al `kubeadm init` per inizializzare il cluster:
```bash
kubeadm init --pod-network-cidr=192.168.0.0/16
```
A noi interessa una --pod-network-cidr=`172.16.0.0/12` (**richiesta classe A o B**) già dichiarata nel config passato per la generazione del primo master control plane (**punto** [`G1` Init del 1° Master control-plane](#g1-init-del-1-master-control-plane));
quindi possiamo **`SALTARE`** questo passaggio!

Installare Tigera Calico Operator:
```bash
kubectl create -f https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml
```
Installare le `Custom Resource`. Prima di applicare lo YAML, editare la parte in cui specifica la `--pod-network-cidr` con `172.16.0.0/12`
```bash
kubectl create -f https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml
```
Check dei POD in running:
```bash
watch kubectl get pods -n calico-system
```
**Remove taints on master to schedule pods on it:**
```bash
kubectl taint nodes --all node-role.kubernetes.io/master-
```

## `G4` Master control-plane join

```bash
kubeadm join ... #utilizza token dell'output in PUNTO F1
```

## `G5` Worker Join

```bash
kubeadm join ... #utilizza token dell'output in PUNTO F1
```
**Label del Worker Role:**
```bash
kubectl label node k8s-worker-0 node-role.kubernetes.io/worker=worker`
```

| return to [`G` K8S](#g-k8s) | return to [`0` INDEX](#0-index) |
| :--- | ---: |

---

# `H` ADDONS

## `H1` metric-server

[metric-server](https://github.com/kubernetes/kube-state-metrics)

**Workaround:** Prima dell'apply, aggiungere il flag `--kubelet-insecure-tls` nel Deployment [HA](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml) \
    **Attenzione! Questo flag non è consigliato in produzione.**

| return to [`H` ADDONS](#h-addons) | return to [`0` INDEX](#0-index) |
| :--- | ---: |

---

# `L` PLUGINS

## `L1` Install KUBE-PROMETHEUS-STACK

[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md)

Installs the <a href="https://github.com/prometheus-operator/kube-prometheus">kube-prometheus stack</a>, a collection of Kubernetes manifests, <a href="http://grafana.com/" rel="nofollow">Grafana</a> dashboards, and <a href="https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/" rel="nofollow">Prometheus rules</a> combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with <a href="https://prometheus.io/" rel="nofollow">Prometheus</a> using the <a href="https://github.com/prometheus-operator/prometheus-operator">Prometheus Operator</a>.

Altre fonti: [1](https://support.tools/post/how-to-install-kube-prometheus-stack/) , [2](https://dev.to/kaitoii11/deploy-prometheus-monitoring-stack-to-kubernetes-with-a-single-helm-chart-2fbd) , [3](https://www.fosstechnix.com/install-prometheus-and-grafana-on-kubernetes-using-helm/)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

kubectl create namespace monitoring

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n prom
# il primo nome dopo install è scelto dall'utente!

kubectl get all -n monitoring
```
**L'output dovrebbe essere simile a questo:**
```bash
NAME                                                         READY   STATUS    RESTARTS   AGE
pod/alertmanager-prom-kube-prometheus-stack-alertmanager-0   2/2     Running   0          2m14s
pod/prom-grafana-6c578f9954-jd4nc                            2/2     Running   0          2m15s
pod/prom-kube-prometheus-stack-operator-598f86d8d7-759tf     1/1     Running   0          2m15s
pod/prom-kube-state-metrics-85d7ddf577-bmnzz                 1/1     Running   0          2m15s
pod/prom-prometheus-node-exporter-6kf8n                      1/1     Running   0          2m16s
pod/prometheus-prom-kube-prometheus-stack-prometheus-0       2/2     Running   1          2m13s

NAME                                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/alertmanager-operated                     ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   2m14s
service/prom-grafana                              ClusterIP   10.107.46.206    <none>        80/TCP                       2m16s
service/prom-kube-prometheus-stack-alertmanager   ClusterIP   10.107.9.211     <none>        9093/TCP                     2m16s
service/prom-kube-prometheus-stack-operator       ClusterIP   10.104.10.237    <none>        443/TCP                      2m16s
service/prom-kube-prometheus-stack-prometheus     ClusterIP   10.110.117.167   <none>        9090/TCP                     2m16s
service/prom-kube-state-metrics                   ClusterIP   10.106.62.213    <none>        8080/TCP                     2m16s
service/prom-prometheus-node-exporter             ClusterIP   10.96.109.34     <none>        9100/TCP                     2m16s
service/prometheus-operated                       ClusterIP   None             <none>        9090/TCP                     2m13s

NAME                                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/prom-prometheus-node-exporter   1         1         1       1            1           <none>          2m16s

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/prom-grafana                          1/1     1            1           2m16s
deployment.apps/prom-kube-prometheus-stack-operator   1/1     1            1           2m16s
deployment.apps/prom-kube-state-metrics               1/1     1            1           2m16s

NAME                                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/prom-grafana-6c578f9954                          1         1         1       2m16s
replicaset.apps/prom-kube-prometheus-stack-operator-598f86d8d7   1         1         1       2m16s
replicaset.apps/prom-kube-state-metrics-85d7ddf577               1         1         1       2m16s

NAME                                                                    READY   AGE
statefulset.apps/alertmanager-prom-kube-prometheus-stack-alertmanager   1/1     2m14s
statefulset.apps/prometheus-prom-kube-prometheus-stack-prometheus       1/1     2m13s
```

### `L1.1` Port-forward (Internally Access to Prom and Grafana Dashboard)

**Access Prometheus Dashboard**
All services are defined as ClusterIP in default configuration. To access, we are going to use port-forward. \
However we can edit the service or edit the value upon deployment to use NodePort or Ingress.

```bash
kubectl port-forward -n monitoring prometheus-prom-kube-prometheus-stack-prometheus-0 9090
#prometheus dashboard

kubectl port-forward -n monitoring alertmanager-prom-kube-prometheus-stack-alertmanager-0 9093
#prometheus alertmanager
```

**Access Grafana Dashboard**
```bash
kubectl port-forward -n monitoring kube-prometheus-stack-grafana 3000
```
L'username di default è `admin` , la password `prom-operator`

### `L1.2` NodePort Services Expose (Externally Access to Prom and Grafana Dashboard)
```bash
kubectl expose svc/prometheus-operated -n monitoring --type=NodePort --target-port=9090 --name=prometheus-operated-ext
#crea service di tipo NodePort (per esporre all'esterno) che si aggancia a svc/prometheus-operated che espone in ClusterIP la dashboard di Prometheus.

kubectl expose svc/alertmanager-operated -n monitoring --type=NodePort --port=9093  --name=alertmanager-operated-ext
#crea service di tipo NodePort (per esporre all'esterno) che si aggancia a svc/alertmanager-operated che espone in ClusterIP l'Alertmanager di Prometheus.
#Nel SECONDO expose, il service ClusterIP aveva TRE porte. Utilizzo --port invece di --target-port

kubectl expose svc/kube-prometheus-stack-grafana -n monitoring --type=NodePort --target-port=3000 --name=kube-prometheus-stack-grafana-ext
```
Prendere nota delle porte assegnate dai 3 service NodePort creati.

### `L1.3` Dashboards Connect

Ora è possibile collegarsi alle dashboard all'interno della stessa rete:
| Prometheus Dashboard        | Prometheus Alertmanager    | 
| :---                        | ---:                       |
| http://10.0.0.31:31026  | http://10.0.0.32:31001 | 

| Grafana Dashboard          | Grafana usr   | Grafana pwd   |
| :---                       | :---:         | ---:          |
| http://10.0.0.31:31361 | admin         | prom-operator |

Nell'URL, posso sostituire l'IP con gli altri IP o i nomi dei master/worker, purché puntino alla porta indicata nell'URL.

### `L1.4` if Prometheus Dashboard TARGETS are down

Dopo aver esposto i service, visitando la Prometheus Dashboard nella sezione `Status>Targets` potrebbe capitare di vedere in down:

#### `L1.4.1` kube-proxy Prometheus target down

`serviceMonitor/monitoring/kube-prometheus-stack-kube-proxy/0 (0/6 down)`

**1.** Editare il configmap del kube-proxy (set the kube-proxy argument for metric-bind-address):
```bash
kubectl edit cm/kube-proxy -n kube-system

...
kind: KubeProxyConfiguration
metricsBindAddress: 0.0.0.0.0:10249 #inserire questi valori
...
```
**2.** eliminare i relativi pod:
```bash
kubectl delete pod -l k8s-app=kube-proxy -n kube-system
```

#### `L1.4.2` kube-scheduler Prometheus target down

`serviceMonitor/monitoring/kube-prometheus-stack-kube-scheduler/0 (0/3 down)`

**1.** Spostarsi nel path e modificare lo YAML indicato:
```bash
cd /etc/kubernetes/manifests
vi kube-scheduler.yaml
```
**2.** Modificare `--bind-address` con value `0.0.0.0`
```YAML
spec:
  containers:
  - command:
    - --bind-address=0.0.0.0 #modificare in 0.0.0.0
```
**3.** Salvare le modifiche e cancellare il POD. \
**Ogni master control-plane ha il suo pod:**
    - `kube-scheduler-k8s-master-0`
    - `kube-scheduler-k8s-master-1`
    - `kube-scheduler-k8s-master-2`
**Ripetere l'operazione su ogni master control-plane!**

#### `L1.4.3` kube-state-metrics Prometheus target down

`serviceMonitor/monitoring/kube-prometheus-stack-kube-state-metrics/0 (0/1 down`

**1.** Spostarsi nel path e modificare lo YAML indicato:
```bash
cd /etc/kubernetes/manifests
vi kube-controller-manager.yaml
```
**2.** Modificare `--bind-address` con value `0.0.0.0`
```YAML
spec:
  containers:
  - command:
    - --bind-address=0.0.0.0 #modificare in 0.0.0.0
```
**3.** Salvare le modifiche e cancellare il POD. \
**Ogni master control-plane ha il suo pod:**
    - `kube-controller-manager-k8s-master-0 `  
    - `kube-controller-manager-k8s-master-1`  
    - `kube-controller-manager-k8s-master-2`
**Ripetere l'operazione su ogni master control-plane!**

### `L1.5` Uninstall kube-prometheus-stack

```bash
helm uninstall kube-prometheus-stack -n monitoring
# nome scelto dall'utente in fase di install

# Remove CRDs:
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

| return to [`L` PLUGINS](#l-plugins) | return to [`0` INDEX](#0-index) |
| :--- | ---: |

## `L2` Install VELERO (Cluster Backup)

### `L2.1` Install Velero CLI
1. [Download](https://github.com/vmware-tanzu/velero/releases/tag/v1.9.1) latest release
```bash
https://github.com/vmware-tanzu/velero/releases/download/v1.9.1/velero-v1.9.1-linux-amd64.tar.gz
```
2. Extract the tarball
```bash
tar -xvf <RELEASE-TARBALL-NAME>.tar.gz
```
3. Move the extracted velero binary to somewhere in your $PATH 
```bash
/usr/local/bin #for most users
```

### `L2.2` Install and Configure Server components

Ci sono due modi:
- `velero install` CLI command
- [Helm Chart](https://vmware-tanzu.github.io/helm-charts/)

# `M` Azure Pipeline Build-Agent Container

[Vedi documentazione Microsoft](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops-2022#environment-variables)

- mkdir ~/dockeragent
- cd ~/dockeragent
- Crea Dockerfile (per UBUNTU 20.04):
```Dockerfile
FROM ubuntu:20.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install node.js and npm
RUN apt-get install -y \
    nodejs npm; \
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs

# Install .NET 6 SDK
RUN apt-get install wget; \ 
    sudo apt-get install -y gpg; \
    wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o microsoft.asc.gpg; \
    mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/; \
    wget https://packages.microsoft.com/config/ubuntu/20.04/prod.list; \
    mv prod.list /etc/apt/sources.list.d/microsoft-prod.list; \
    chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg; \
    chown root:root /etc/apt/sources.list.d/microsoft-prod.list; \
    apt-get update && \
    apt-get install -y dotnet-sdk-6.0
    
# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY ./start.sh .

RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]
```
Tasks might depend on executables that your container is expected to provide. For instance, you must add the zip and unzip packages to the RUN apt-get command in order to run the ArchiveFiles and ExtractFiles tasks. Also, as this is a Linux Ubuntu image for the agent to use, you can customize the image as you need. E.g.: if you need to build .NET applications you can follow the document Install the .NET SDK or the .NET Runtime on Ubuntu and add that to your image.

Save the following content to ~/dockeragent/start.sh, making sure to use Unix-style (LF) line endings:

```shell
#!/bin/bash
set -e

if [ -z "$AZP_URL" ]; then
  echo 1>&2 "error: missing AZP_URL environment variable"
  exit 1
fi

if [ -z "$AZP_TOKEN_FILE" ]; then
  if [ -z "$AZP_TOKEN" ]; then
    echo 1>&2 "error: missing AZP_TOKEN environment variable"
    exit 1
  fi

  AZP_TOKEN_FILE=/azp/.token
  echo -n $AZP_TOKEN > "$AZP_TOKEN_FILE"
fi

unset AZP_TOKEN

if [ -n "$AZP_WORK" ]; then
  mkdir -p "$AZP_WORK"
fi

export AGENT_ALLOW_RUNASROOT="1"

cleanup() {
  if [ -e config.sh ]; then
    print_header "Cleanup. Removing Azure Pipelines agent..."

    # If the agent has some running jobs, the configuration removal process will fail.
    # So, give it some time to finish the job.
    while true; do
      ./config.sh remove --unattended --auth PAT --token $(cat "$AZP_TOKEN_FILE") && break

      echo "Retrying in 30 seconds..."
      sleep 30
    done
  fi
}

print_header() {
  lightcyan='\033[1;36m'
  nocolor='\033[0m'
  echo -e "${lightcyan}$1${nocolor}"
}

# Let the agent ignore the token env variables
export VSO_AGENT_IGNORE=AZP_TOKEN,AZP_TOKEN_FILE

print_header "1. Determining matching Azure Pipelines agent..."

AZP_AGENT_PACKAGES=$(curl -LsS \
    -u user:$(cat "$AZP_TOKEN_FILE") \
    -H 'Accept:application/json;' \
    "$AZP_URL/_apis/distributedtask/packages/agent?platform=$TARGETARCH&top=1")

AZP_AGENT_PACKAGE_LATEST_URL=$(echo "$AZP_AGENT_PACKAGES" | jq -r '.value[0].downloadUrl')

if [ -z "$AZP_AGENT_PACKAGE_LATEST_URL" -o "$AZP_AGENT_PACKAGE_LATEST_URL" == "null" ]; then
  echo 1>&2 "error: could not determine a matching Azure Pipelines agent"
  echo 1>&2 "check that account '$AZP_URL' is correct and the token is valid for that account"
  exit 1
fi

print_header "2. Downloading and extracting Azure Pipelines agent..."

curl -LsS $AZP_AGENT_PACKAGE_LATEST_URL | tar -xz & wait $!

source ./env.sh

print_header "3. Configuring Azure Pipelines agent..."

./config.sh --unattended \
  --agent "${AZP_AGENT_NAME:-$(hostname)}" \
  --url "$AZP_URL" \
  --auth PAT \
  --token $(cat "$AZP_TOKEN_FILE") \
  --pool "${AZP_POOL:-Default}" \
  --work "${AZP_WORK:-_work}" \
  --replace \
  --acceptTeeEula & wait $!

print_header "4. Running Azure Pipelines agent..."

trap 'cleanup; exit 0' EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

chmod +x ./run.sh #non run-docker.sh

# To be aware of TERM and INT signals call run.sh
# Running it with the --once flag at the end will shut down the agent after the build is executed
./run.sh "$@" & wait $!

#ATTENZIONE! NELLA DOC MICROSOFT VIENE ERRONEAMENTECHIAMATO run-docker.sh, RINOMINARLO IN run.sh
```
You must also use a container orchestration system, like Kubernetes or Azure Container Instances, to start new copies of the container when the work completes.

Run the following command within that directory:
```shell
docker build -t dockeragent:latest .
```

This command builds the Dockerfile in the current directory.

The final image is tagged dockeragent:latest. You can easily run it in a container as dockeragent, because the latest tag is the default if no tag is specified.

Generare un deployment e inserire le seguenti env nel container:
- `AZP_URL` Azure DevOps instance
- `AZP_TOKEN` **PAT** token
- `AZP_AGENT_NAME` mydockeragent dockeragent:latest
- `AZP_POOL` Agent Pool

```YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: build-agent
spec:
  selector:
    matchLabels:
      app: build-agent
  template:
    metadata:
      labels:
        app: build-agent
    spec:
      containers:
      - name: build-agent-container
        image: <your-registry>/buildagent:0.2.5
        resources:
          limits: {}
        env:
          - name: AZP_URL
            value: https://devops.example.internal:444 
          - name: AZP_POOL
            value: k8s #nome Agent Pool
          - name: AZP_TOKEN
            valueFrom:
              secretKeyRef:
                name: build-agent-secret
                key: AZP_TOKEN
          - name: AZP_AGENT_NAME
            value: build-agent-name
---
apiVersion: v1
kind: Secret
metadata:
  name: build-agent-secret
  labels:
        app: build-agent
type: Opaque
data:
  AZP_TOKEN: #inserire token encoded in base64
  #i permessi dell'agentpool da cui generare il token devono essere read & manage
```

## `M1` Testing buildagent on Azure DevOps Pipeline

Login on:
```
https://devops.example.internal:444/<your-org>/<your-project>/
```

### `M1.1` Create a Pipeline

- Go to `Pipelines`
- `New pipeline` > `Use the classic editor to create a pipeline without YAML.`
- Select a source: `Azure Repos Git`
- Select a template: `Empty pipeline`
- Give a name & select `k8s` Agent Pool, the one on wich the token is generated.
- Add a task to the `Agent job` and select `Bash`.
- Select type:`Inline` & write under `Script` field:
```bash
node --version
npm --version
```
### `M1.2` Launch a Pipeline
- `Save & queue` to launch it.
- `Queue` when launching an existing pipeline.
