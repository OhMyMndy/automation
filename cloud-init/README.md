# Cloud init


## With Multipass

### Hashicorp Nomad

```bash
multipass launch --cloud-init nomad/cloud-init.yml --name nomad
multipass shell nomad

multipass delete nomad --purge
```


### Canonical MicroStack (OpenStack) 

```bash
multipass launch --cloud-init microstack/cloud-init.yml --name microstack --bridged --mem 8G --cpus 6
multipass shell microstack

multipass delete microstack --purge
```


### Minimal Nvim setup

```bash
multipass launch --cloud-init nvim-minimal/cloud-init.yml --name nvim --mem 1G --cpus 2
# or 
#  multipass launch --cloud-init nvim-minimal/cloud-init.yml --name nvim --mem 1G --cpus 2 --mount ($env:USERPROFILE +"\dotfiles\:/home/ubuntu/dotfiles")
multipass shell nvim

multipass delete nvim --purge
```
