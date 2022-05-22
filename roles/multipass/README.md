# Multipass

## Linux

### Installation

```bash
sudo snap install multipass
sudo snap connect multipass:libvirt
```

[Install libvirt](../libvirt/README.md#installation)

### Configuration

Backend configuration

`multipass set local.driver lxd`

`multipass set local.driver libvirt`

### Launching VM's

- Rocky linux (running other cloud images than Ubuntu is only supported on Linux)
    `multipass launch -n rocky -c 2 -d 10G -m 4G https://download.rockylinux.org/pub/rocky/8.6/images/Rocky-8-GenericCloud.latest.x86_64.qcow2`
