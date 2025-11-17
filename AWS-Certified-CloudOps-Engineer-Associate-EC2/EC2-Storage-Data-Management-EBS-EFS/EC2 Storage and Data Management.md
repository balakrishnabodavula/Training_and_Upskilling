EC2 Storage and Data Management - EBS and EFS
Lab 1: EBS Volume Management
Create and Attach EBS Volumes
# Create EBS volume
aws ec2 create-volume \
  --size 20 \
  --volume-type gp3 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=CloudOps-Volume}]'

# Attach volume to instance
aws ec2 attach-volume \
  --volume-id vol-xxxxxxxxx \
  --instance-id i-xxxxxxxxx \
  --device /dev/sdf

# List volumes
aws ec2 describe-volumes \
  --filters "Name=tag:Name,Values=CloudOps-Volume"

# Detach volume
aws ec2 detach-volume \
  --volume-id vol-xxxxxxxxx
Format and Mount EBS Volume
# SSH into instance and format volume
sudo mkfs -t xfs /dev/xvdf

# Create mount point
sudo mkdir /data

# Mount volume
sudo mount /dev/xvdf /data

# Add to fstab for persistent mounting
echo '/dev/xvdf /data xfs defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Verify mount
df -h
Terraform EBS Configuration
# ebs.tf
resource "aws_ebs_volume" "cloudops_volume" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true
  
  tags = {
    Name = "CloudOps-Volume"
  }
}

resource "aws_volume_attachment" "cloudops_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.cloudops_volume.id
  instance_id = aws_instance.cloudops_instance.id
}

resource "aws_ebs_snapshot" "cloudops_snapshot" {
  volume_id = aws_ebs_volume.cloudops_volume.id
  
  tags = {
    Name = "CloudOps-Snapshot"
  }
}
Lab 2: EBS Snapshots and Backup
Create and Manage Snapshots
# Create snapshot
aws ec2 create-snapshot \
  --volume-id vol-xxxxxxxxx \
  --description "CloudOps volume backup $(date +%Y-%m-%d)"

# List snapshots
aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=volume-id,Values=vol-xxxxxxxxx"

# Create volume from snapshot
aws ec2 create-volume \
  --snapshot-id snap-xxxxxxxxx \
  --availability-zone us-east-1a \
  --volume-type gp3

# Copy snapshot to another region
aws ec2 copy-snapshot \
  --source-region us-east-1 \
  --source-snapshot-id snap-xxxxxxxxx \
  --destination-region us-west-2 \
  --description "Cross-region backup"
Automated Snapshot Script
#!/bin/bash
# snapshot-backup.sh

VOLUME_ID="vol-xxxxxxxxx"
RETENTION_DAYS=7

# Create snapshot
SNAPSHOT_ID=$(aws ec2 create-snapshot \
  --volume-id $VOLUME_ID \
  --description "Automated backup $(date +%Y-%m-%d)" \
  --query 'SnapshotId' \
  --output text)

echo "Created snapshot: $SNAPSHOT_ID"

# Tag snapshot
aws ec2 create-tags \
  --resources $SNAPSHOT_ID \
  --tags Key=AutoBackup,Value=true Key=CreatedDate,Value=$(date +%Y-%m-%d)

# Delete old snapshots
OLD_SNAPSHOTS=$(aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:AutoBackup,Values=true" \
  --query "Snapshots[?StartTime<='$(date -d "$RETENTION_DAYS days ago" --iso-8601)'].SnapshotId" \
  --output text)

for snapshot in $OLD_SNAPSHOTS; do
  echo "Deleting old snapshot: $snapshot"
  aws ec2 delete-snapshot --snapshot-id $snapshot
done
Lab 3: EFS File System
Create EFS File System
# Create EFS file system
aws efs create-file-system \
  --creation-token cloudops-efs-$(date +%s) \
  --performance-mode generalPurpose \
  --throughput-mode provisioned \
  --provisioned-throughput-in-mibps 100 \
  --encrypted

# Create mount targets
aws efs create-mount-target \
  --file-system-id fs-xxxxxxxxx \
  --subnet-id subnet-xxxxxxxxx \
  --security-groups sg-xxxxxxxxx

# Create access point
aws efs create-access-point \
  --file-system-id fs-xxxxxxxxx \
  --posix-user Uid=1001,Gid=1001 \
  --root-directory Path="/secure",CreationInfo='{OwnerUid=1001,OwnerGid=1001,Permissions=755}'
Mount EFS File System
# Install EFS utils
sudo yum install -y amazon-efs-utils

# Create mount point
sudo mkdir /efs

# Mount using EFS helper
sudo mount -t efs fs-xxxxxxxxx:/ /efs

# Mount with encryption in transit
sudo mount -t efs -o tls fs-xxxxxxxxx:/ /efs

# Add to fstab
echo 'fs-xxxxxxxxx.efs.us-east-1.amazonaws.com:/ /efs efs defaults,_netdev' | sudo tee -a /etc/fstab
Terraform EFS Configuration
# efs.tf
resource "aws_efs_file_system" "cloudops_efs" {
  creation_token = "cloudops-efs"
  
  performance_mode                = "generalPurpose"
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = 100
  encrypted                       = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = {
    Name = "CloudOps-EFS"
  }
}

resource "aws_efs_mount_target" "cloudops_mount" {
  count = length(var.subnet_ids)
  
  file_system_id  = aws_efs_file_system.cloudops_efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name_prefix = "efs-sg"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_access_point" "cloudops_ap" {
  file_system_id = aws_efs_file_system.cloudops_efs.id
  
  posix_user {
    gid = 1001
    uid = 1001
  }
  
  root_directory {
    path = "/secure"
    creation_info {
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "755"
    }
  }
  
  tags = {
    Name = "CloudOps Access Point"
  }
}
Lab 4: Storage Performance Optimization
EBS Performance Tuning
# Check current IOPS and throughput
aws ec2 describe-volumes \
  --volume-ids vol-xxxxxxxxx \
  --query 'Volumes[0].[Iops,Throughput,VolumeType]'

# Modify volume for better performance
aws ec2 modify-volume \
  --volume-id vol-xxxxxxxxx \
  --volume-type gp3 \
  --iops 4000 \
  --throughput 250

# Monitor volume modifications
aws ec2 describe-volumes-modifications \
  --volume-ids vol-xxxxxxxxx
Storage Monitoring
# Create CloudWatch alarm for volume queue depth
aws cloudwatch put-metric-alarm \
  --alarm-name "EBS-High-Queue-Depth" \
  --alarm-description "EBS volume queue depth high" \
  --metric-name VolumeQueueLength \
  --namespace AWS/EBS \
  --statistic Average \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=VolumeId,Value=vol-xxxxxxxxx \
  --evaluation-periods 2
Lab 5: Instance Store
Instance Store Management
# List instance store devices
lsblk

# Format instance store
sudo mkfs.xfs /dev/nvme1n1

# Mount instance store
sudo mkdir /instance-store
sudo mount /dev/nvme1n1 /instance-store

# Set up RAID for multiple instance store volumes
sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/nvme1n1 /dev/nvme2n1
sudo mkfs.xfs /dev/md0
sudo mount /dev/md0 /raid-store
Terraform Instance Store
# instance-store.tf
resource "aws_instance" "storage_optimized" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "m5d.large"  # Instance with NVMe SSD
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Format and mount instance store
    mkfs.xfs /dev/nvme1n1
    mkdir /instance-store
    mount /dev/nvme1n1 /instance-store
    EOF
  )
  
  tags = {
    Name = "Storage Optimized Instance"
  }
}
Lab 6: Data Lifecycle Management
EBS Lifecycle Policy
# Create lifecycle policy
cat > lifecycle-policy.json << EOF
{
  "ResourceTypes": ["VOLUME"],
  "TargetTags": [
    {
      "Key": "Backup",
      "Value": "Required"
    }
  ],
  "Schedules": [
    {
      "Name": "DailySnapshots",
      "CreateRule": {
        "Interval": 24,
        "IntervalUnit": "HOURS",
        "Times": ["03:00"]
      },
      "RetainRule": {
        "Count": 7
      },
      "CopyTags": true
    }
  ]
}
EOF

# Create lifecycle policy
aws dlm create-lifecycle-policy \
  --execution-role-arn arn:aws:iam::123456789012:role/AWSDataLifecycleManagerDefaultRole \
  --description "Daily EBS snapshots" \
  --state ENABLED \
  --policy-details file://lifecycle-policy.json
Terraform Lifecycle Management
# lifecycle.tf
resource "aws_dlm_lifecycle_policy" "ebs_backup" {
  description        = "Daily EBS snapshots"
  execution_role_arn = aws_iam_role.dlm_role.arn
  state             = "ENABLED"
  
  policy_details {
    resource_types   = ["VOLUME"]
    target_tags = {
      Backup = "Required"
    }
    
    schedule {
      name = "DailySnapshots"
      
      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }
      
      retain_rule {
        count = 7
      }
      
      copy_tags = true
    }
  }
}

resource "aws_iam_role" "dlm_role" {
  name = "AWSDataLifecycleManagerDefaultRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })
}
Best Practices
Use appropriate volume types for workload requirements
Enable encryption for sensitive data
Regular snapshots for backup and recovery
Monitor performance metrics
Use EFS for shared file storage
Optimize IOPS and throughput based on needs
Implement lifecycle policies for cost optimization
Monitoring Storage
# Check volume utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/EBS \
  --metric-name VolumeReadOps \
  --dimensions Name=VolumeId,Value=vol-xxxxxxxxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum

# Monitor EFS performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/EFS \
  --metric-name TotalIOBytes \
  --dimensions Name=FileSystemId,Value=fs-xxxxxxxxx \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Sum
Cleanup
# Delete EBS volume
aws ec2 delete-volume --volume-id vol-xxxxxxxxx

# Delete EFS file system
aws efs delete-file-system --file-system-id fs-xxxxxxxxx

# Delete snapshots
aws ec2 delete-snapshot --snapshot-id snap-xxxxxxxxx