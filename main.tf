
# run these 3 commands on PVE teminal first
# pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"
# pveum user add terraform-prov@pve --password terraform
# pveum aclmod / -user terraform-prov@pve -role TerraformProv

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4" # Use the latest version if needed
    }
  }
}
provider "proxmox" {
  pm_api_url      = "http://192.168.0.2:8006/api2/json"
  pm_user         = "terraform-prov@pve"
  pm_password     = "terraform"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "vm" {
  count = 4

  name = "loc-k8s-node-${count.index}"
  vmid = 101 + count.index * 10
  desc = "Local kube cluster node ${count.index}"

  target_node            = "pve"
  define_connection_info = true
  bios                   = "seabios"
  startup                = ""
  vm_state               = "running"
  protection             = false
  tablet                 = true
  boot                   = "order=scsi0;net0"
  clone                  = "template0"
  clone_wait             = 10
  full_clone             = true

  agent   = 1
  os_type = "centos"
  onboot  = true

  cores   = count.index == 0 ? 4 : 2
  sockets = 1
  cpu     = "host"

  memory   = 6144
  scsihw   = "virtio-scsi-single"
  bootdisk = "scsi0"

  machine = "q35"

  # cloud init
  ciuser     = "root"
  cipassword = "kai"
  # sshkeys     = file("${path.module}/id_ed25519.pub")
  sshkeys   = file("/home/kai/.ssh/id_ed25519.pub")
  ipconfig0 = "ip=192.168.0.${count.index + 101}/24,gw=192.168.0.1"

  disks {
    scsi {
      scsi0 {
        disk {
          size     = "32G"
          storage  = "local-lvm"
          iothread = true
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

}
