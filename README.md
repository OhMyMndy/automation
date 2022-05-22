# Automation

## Dependencies

- Ansible
  - `sudo apt-get install python3-pip -y`
  - `pip3 install ansible`

## Run a specific role

```bash
ansible-playbook --connection=local --inventory=127.0.0.1, --ask-become-pass playbook.yml -v -t multipass
 ```

- Docker

  ```bash
  ansible-galaxy role install geerlingguy.docker
  ansible-playbook --connection=local --inventory=127.0.0.1, --ask-become-pass playbook.yml -v -t docker -e 'docker_users=[mandy]'
  ```
