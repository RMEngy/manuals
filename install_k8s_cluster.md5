# Настройка кластера Kubernetes с Kubeadm
## Предварительная настройка системы
### Настройка файла /etc/hosts
>Данный эпат необходим в случае, когда у нас отсутствет DNS сервер.

На этом первом шаге вы настроите системное имя хоста и файл /etc/hosts на всех ваших серверах. Для этой демонстрации мы будем использовать следующие серверы.
```
Hostname               IP Address        Used as
------------------------------------------------------
lab-k8s-master-01a     192.168.3.206     control-plane
lab-k8s-worker-01a     192.168.5.207     worker1 node
lab-k8s-worker-01b     192.168.5.208     worker2 node
```
Запустите следующую команду **hostnamectl** ниже, чтобы настроить системное имя хоста на каждом сервере.

Для узла плоскости управления выполните следующую команду, чтобы установить системное имя хоста **lab-k8s-master-01a**.
```bash
# setup hostname control-plane
$ sudo hostnamectl set-hostname lab-k8s-master-01a
```
Для рабочих узлов Kubernetes выполните следующую команду **hostnamectl**.
```bash
# setup hostname worker1
$ sudo hostnamectl set-hostname lab-k8s-worker-01a
```
```bash
# setup hostname worker2
$ sudo hostnamectl set-hostname lab-k8s-worker-01b
```
Затем измените файл **/etc/hosts** на всех серверах. Добавьте следующую конфигурацию в файл. Убедитесь, что каждое имя хоста указывает на правильный IP-адрес.
```bash
$ sudo nano /etc/hosts

# Добавляем наши сервера
192.168.3.206 lab-k8s-master-01a
192.168.3.207 lab-k8s-worker-01a
192.168.3.208 lab-k8s-worker-01b
```
Сохраните и закройте файл, когда закончите.
### Настройка брандмауэра
Отключаем его и убираем из автозагрузки. В данном случае он нам не поднадобится и будет только мешать.
### Подлючение модулей ядра и отключить SWAP
Kubernetes требовал, чтобы модули ядра **overlay** и **br_netfilter** были включены на всех серверах. Это позволит **iptbales** видеть мостовой трафик. Также вам нужно будет включить переадресацию портов и отключить **SWAP**.

Запустите следующую команду, чтобы включить модули ядра **overlay** и **br_netfilter**.
```bash
$ sudo modprobe overlay
$ sudo modprobe br_netfilter
```
Чтобы сделать его постоянным, создайте файл конфигурации в **/etc/modules-load.d/k8s.conf**. Это позволит системам Linux включать модули ядра во время загрузки системы.
```bash
$ cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```
Затем создайте необходимые параметры **systemctl** с помощью следующей команды.
```bash
$ cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
```
Чтобы применить новую конфигурацию sysctl без перезагрузки, используйте следующую команду. Вы должны получить список параметров sysctl по умолчанию в вашей системе и убедиться, что вы получили параметры sysctl, которые вы только что добавили в файл **k8s.conf**.
```bash
$ sudo sysctl --system
```
Чтобы отключить SWAP, вам нужно будет прокомментировать конфигурацию SWAP в файле **/etc/fstab**. Это можно сделать с помощью одной команды через sed.
```bash
$ sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
Теперь отключите **SWAP** в текущем сеансе с помощью приведенной ниже команды. Затем убедитесь, что **SWAP** отключен с помощью команды **free -m**. Вы должны увидеть, что **SWAP** имеет значения **«0»**, что означает, что теперь он отключен.
```bash
$ sudo swapoff -a
$ free -m
```
## Установка среды выполнения контейнера: Containerd
Чтобы настроить кластер **Kubernetes**, необходимо установить среду выполнения контейнера на всех серверах, чтобы могли работать поды. Для развертываний **Kubernetes** можно использовать несколько сред выполнения контейнеров, таких как containerd, **CRI-O, Mirantis Container Runtime и Docker Engine (через cri-dockerd)**.

Мы будем использовать **containerd** в качестве контейнера для нашего развертывания **Kubernetes**. Итак, вы установите **containerd** на все серверы, панель управления и рабочие узлы.

Есть несколько способов установить **containerd**, самый простой из них — использовать готовые бинарные пакеты, предоставленные репозиторием **Docker**.

Теперь выполните следующую команду, чтобы добавить репозиторий **Docker и ключ GPG**.
```bash
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```
Обновите индекс пакета в вашей системе
```bash
$ sudo apt update
```
Теперь установите пакет **containerd** с помощью приведенной ниже команды **apt**. И начнется установка.
```bash
$ sudo apt install containerd.io
```
После завершения установки выполните следующую команду, чтобы остановить службу **containerd**.
```bash
$ sudo systemctl stop containerd
```
Создайте резервную копию из-под пользователя **root** конфигурации **containerd** по умолчанию и создайте новую, используя следующую команду.
```bash
$ sudo -i
$ mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
$ containerd config default > /etc/containerd/config.toml
# Теперь измените файл конфигурации containerd /etc/containerd/config.toml, используя следующую команду.
$ nano /etc/containerd/config.toml
# Измените значение драйвера cgroup SystemdCgroup=false на SystemdCgroup=true. Это включит драйвер systemd cgroup для среды выполнения контейнера containerd.
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
$ exit
```
Когда вы закончите, сохраните и закройте файл. Затем выполните следующую команду **systemctl**, чтобы запустить службу **containerd**.
```bash
$ sudo systemctl start containerd
```
Наконец, проверьте и подтвердите службу **containerd**, используя приведенную ниже команду. Вы должны увидеть, что **containerd** включен и будет запускаться автоматически при загрузке системы. И текущий статус службы **containerd** работает.
```bash
$ sudo systemctl is-enabled containerd
$ sudo systemctl status containerd
```
## Установка пакета Kubernetes
Вы установили среду выполнения контейнера **containerd**. Теперь вы установите пакеты **Kubernetes** на все свои сервера для кластера **Kubernetes**. Сюда входят **kubeadm** для начальной загрузки кластера **Kubernetes, kubelet** — основной компонент кластера **Kubernetes и kubectl** — утилита командной строки для управления кластером **Kubernetes**.

В этом примере мы будем устанавливать пакеты **Kubernetes**, используя репозиторий, предоставленный **Kubernetes**. 

>Примечание: В некоторых релизах сеймейства **ОС Debian** старше файл **/etc/apt/keyrings** по умолчанию не существует. Вы можете создать этот каталог, если вам нужно, сделав его доступным для чтения всем, но доступным для записи только администраторами.

```bash
$ sudo apt install apt-transport-https ca-certificates curl -y
```
Теперь добавьте репозиторий **Kubernetes** и ключ **GPG**.
```bash
$ sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
$ echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
Обновите индекс пакета **apt**, установите **kubelet, kube adm и kubectl** и закрепите их версию.
```bash
$ sudo apt-get update
$ sudo apt-get install -y kubelet kubeadm kubectl
$ sudo apt-mark hold kubelet kubeadm kubectl
```
## Установка подключаемого модуля CNI (контейнерный сетевой интерфейс): Flannel
Kubernetes поддерживает различные подключаемые модули **Container Network**, такие как **AWS VPC для Kubernetes, Azure CNI, Cilium, Calico, Flannel** и многие другие. В этом примере мы будем использовать **Flannel** в качестве подключаемого модуля **CNI** для развертывания **Kubernetes**. А для этого вам нужно было установить бинарный файл **Flannel** на узлы **Kubernetes**.

Выполните приведенную ниже команду, чтобы создать новый каталог **/opt/bin**. Затем загрузите в него бинарный файл **Flannel**.
```bash
$ sudo mkdir -p /opt/bin/
$ sudo curl -fsSLo /opt/bin/flanneld https://github.com/flannel-io/flannel/releases/download/v0.22.0/flanneld-amd64
```
Теперь сделайте двоичный файл **flanneld** исполняемым, изменив разрешение файла с помощью приведенной ниже команды. Этот двоичный файл **flanneld** будет выполняться автоматически, когда вы настраиваете сетевое дополнение **Pod**.
```bash
$ sudo chmod +x /opt/bin/flanneld
```
## Инициализация плоскости управления Kubernetes
Вы выполнили все зависимости и требования для развертывания кластера **Kubernetes**. Теперь вы запустите кластер **Kubernetes**, впервые инициализировав узел **Control Plane**. В этом примере плоскость управления Kubernetes будет установлена на сервере **lab-k8s-master-01a с IP-адресом 192.168.3.206**.

Перед инициализацией узла **Control Plane** выполните следующую команду, чтобы проверить, включены ли модули ядра **br_netfilter**. Если вы получите вывод команды, это означает, что модуль **br_netfilter** включен.
```bash
lsmod | grep br_netfilter
```
Затем выполните следующую команду, чтобы загрузить образы, необходимые для кластера **Kubernetes**. Эта команда загрузит все образы контейнеров, необходимые для создания кластера **Kubernetes**, такие как **coredns, сервер kube-api и т. д., kube-controller, kube-proxy и образ контейнера pause**.
```bash
$ sudo kubeadm config images pull
```
После завершения загрузки выполните следующую команду.
```bash
$ sudo kubeadm init
``` 
Это - инициализирует кластер Kubernetes на сервере **lab-k8s-master-01a**. Этот узел **lab-k8s-master-01a** будет автоматически выбран в качестве плоскости управления Kubernetes, поскольку это первая инициализация кластера.

+ Кроме того, в этом примере мы указываем в качестве сети для модулей значение **10.244.0.0/16**, которое является диапазоном сети по умолчанию для подключаемого модуля **Flannel CNI**.
+ **--apiserver-advertise-address** определяет, на каком IP-адресе будет работать сервер **API Kubernetes**. В этом примере используется внутренний IP-адрес **192.168.3.206**.
+ Для параметра **--cri-socket** здесь мы указываем сокет **CRI** для сокета среды выполнения контейнера, который доступен на **/run/containerd/containerd.sock** . Если вы используете другую среду выполнения контейнера, вы должны изменить путь к файлу сокета или можете просто удалить эту опцию **--cri-socket**, потому что **kubeadm** автоматически обнаружит сокет среды выполнения контейнера. В нашем случае мы так и поступим.
```bash
$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 \
--apiserver-advertise-address=192.168.3.206 
```
Когда инициализация завершена, вы можете увидеть сообщение, такое как «Ваша плоскость управления Kubernetes успешно инициализирована!» с некоторыми важными выходными сообщениями для настройки учетных данных Kubernetes и развертывания сетевой надстройки **Pod**, как добавить рабочий узел в свой кластер **Kubernetes**.

Прежде чем вы начнете использовать кластер **Kubernetes**, вам необходимо настроить учетные данные **Kubernetes**. Выполните следующую команду, чтобы настроить учетные данные **Kubernetes**.
```bash
$ sudo mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Теперь вы можете использовать команду **kubectl** для взаимодействия с вашим кластером **Kubernetes**. Выполните следующую команду **kubectl**, чтобы проверить информацию о кластере **Kubernetes**. И вы должны увидеть плоскость управления **Kubernetes** и работающие ядра.
```bash
$ sudo kubectl cluster-info
```
Чтобы получить полную информацию о вашем Kubernetes, вы можете использовать опцию дампа — так:
```bash
$ sudo kubectl cluster-info dump
```
После запуска плоскости управления Kubernetes выполните следующую команду, чтобы установить сетевой подключаемый модуль **Flannel Pod**. Эта команда автоматически запустит бинарный файл **flanneld**.
```bash
$ sudo kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```
Проверьте список запущенных модулей в **Kubernetes** с помощью следующей команды. если ваша установка **Kubernetes** прошла успешно, вы должны увидеть, что все основные модули для **Kubernetes** запущены.
```bash
$ sudo kubectl get pods --all-namespaces
```
## Добавление рабочих узлов в Kubernetes
После инициализации плоскости управления Kubernetes на сервере **lab-k8s-master-01a** вы добавите рабочие узлы **lab-k8s-worker-01a и lab-k8s-worker-01b в кластер Kubernetes**.

Перейдите на сервер **lab-k8s-worker-01a** и выполните приведенную ниже команду **kubeadm join**, чтобы добавить **lab-k8s-worker-01a** в кластер **Kubernetes**. У вас могут быть другие токен и **ca-cert-hash**, вы можете увидеть подробную информацию об этой информации в выходном сообщении при инициализации узла **Control Plane**.
```bash
$ sudo kubeadm join 192.168.3.206:6443 --token sju3ug.z5e3kfpmma7159js \
--discovery-token-ca-cert-hash sha256:d7a03cd9f6beba3c07e2d53d4f8e48597c328cbab9c713153c7acd3390a9c337
```
В следующем выводе видно, что к серверу **lab-k8s-worker-01a** присоединяется кластер **Kubernetes**.

Затем перейдите на сервер **lab-k8s-worker-01b** и запустите команду **kubeadm join**, чтобы добавить **lab-k8s-worker-01b в кластер Kubernetes**.
```bash
$ sudo kubeadm join 192.168.3.206:6443 --token sju3ug.z5e3kfpmma7159js \
--discovery-token-ca-cert-hash sha256:d7a03cd9f6beba3c07e2d53d4f8e48597c328cbab9c713153c7acd3390a9c337
```
Вы увидите такое же выходное сообщение, когда процесс завершится.

Теперь вернитесь к серверу **Control Plane lab-k8s-master-01a** и выполните следующую команду, чтобы проверить все запущенные модули в кластере **Kubernetes**. Вы должны увидеть дополнительные модули на каждом компоненте **Kubernetes**.
```bash
$ sudo kubectl get pods --all-namespaces
```
Наконец, проверьте и подтвердите все доступные узлы в кластере Kubernetes с помощью приведенной ниже команды **kubectl**. Вы должны увидеть, что сервер **lab-k8s-master-01a** работает в качестве плоскости управления **Kubernetes**, а сервер **lab-k8s-worker-01a**  и серверы **lab-k8s-worker-01b**  работают как рабочий узел.
```bash
$ sudo kubectl get nodes -o wide
```
## Заключение
В рамках этого руководства вы завершили развертывание кластера **Kubernetes** с тремя узлами серверов. Кластер **Kubernetes** работает с одной плоскостью управления и двумя рабочими узлами. Он работает с **containerd** в качестве среды выполнения контейнера для вашего кластера **Kubernetes** и с сетевым плагином **Flannel** для сетевого подключения модулей в вашем кластере. Вы полностью настроили кластер **Kubernetes**, вы можете начать развертывание своих приложений в кластере **Kubernetes** или попробовать установить панель управления **Kubernetes**, чтобы узнать больше о вашей среде **Kubernetes**.
