# Variable used to identify the instance that the volumes belong to.
variable "instance_owner" {
  type    = string
  default = "instance_one"
}

# Local Terraform block named "dev_map" that maps device names to device paths in AWS.
locals {
  dev_map = {"dev_name_one" = "/dev/sdh", "dev_name_two" = "/dev/sdi"}
}

# The disk_info variable is used to store disk information about the pre-created volumes.
variable "disk_info" {
  type = map(any)
  default = {
    disk1 = {
      disk_name      = "the_first_disk"
      zone           = "us-east-1a"
      instance_owner = "instance_one"
      disk_path      = "/dev/sdh"
    },
    disk2 = {
      disk_name      = "the_second_disk"
      zone           = "us-east-1b"
      instance_owner = "instance_two"
      disk_path      = "/dev/sdh"
    },
    disk3 = {
      disk_name      = "the_third_disk"
      zone           = "us-east-1a"
      instance_owner = "instance_one"
      disk_path      = "/dev/sdi"
    },
  }
}

# Create a local block called "filtered_disks" that filters the disks from "disk_info".
locals {
  filtered_disks = {
    for disk_name, disk in var.disk_info : disk_name => disk if disk.instance_owner == var.instance_owner
  }
}

# Find the disk by their name tag and create volume instances based on the instance_owner value.
data "aws_ebs_volume" "example" {
  count = length(local.filtered_disks)
  filter {
    name   = "tag:Name"
    values = [values(local.filtered_disks)[count.index].disk_name]
  }
}

# Create the AWS instance.
resource "aws_instance" "example" {
  ami               = "ami-0aa7d40eeae50c9a9"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  tags = {
    Name = var.instance_owner
  }
}

# Create as many volume attachments as there are volumes.
resource "aws_volume_attachment" "ebs_att" {
  count = length(data.aws_ebs_volume.example)
  device_name = values(local.dev_map)[count.index]
  volume_id   = data.aws_ebs_volume.example[count.index].id
  instance_id = aws_instance.example.id
}
