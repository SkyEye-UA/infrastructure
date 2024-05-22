terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create a VPC
resource "aws_vpc" "sky_eye_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "SkyEyeVpc"
  }
}


data "aws_availability_zones" "available" {
  state = "available"
}

# Create  subnets

resource "aws_subnet" "SkyEyeSubnets" {
    count = length(var.subnet_cidr_blocks)

    vpc_id                  = aws_vpc.sky_eye_vpc.id
    cidr_block              = var.subnet_cidr_blocks[count.index]

    availability_zone = element(data.aws_availability_zones.available.names, count.index)

    map_public_ip_on_launch = true
    tags = {
      "Name" = "PublicSubnet${count.index + 1}"
    }
  }

  # Creating Internet Gateway IGW
  resource "aws_internet_gateway" "skyeyeigw" {
    vpc_id = aws_vpc.sky_eye_vpc.id
    tags = {
      "Name" = "skyeyeIGW"
    }
  }

   # Creating Route Table
  resource "aws_route_table" "skyeyeroutetable" {
    vpc_id = aws_vpc.sky_eye_vpc.id
    tags = {
      "Name" = "SkyEyeRouteTable"
    }
  }

  # Create a Route in the Route Table with a route to IGW
  resource "aws_route" "skyeyeigw_route" {
    route_table_id         = aws_route_table.skyeyeroutetable.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.skyeyeigw.id
  }

  # Associate Subnets with the Route Table
  resource "aws_route_table_association" "SkyEyeSubnetAssociation" {
    count           = length(aws_subnet.SkyEyeSubnets[*].id)
    route_table_id = aws_route_table.skyeyeroutetable.id
    subnet_id      = element(aws_subnet.SkyEyeSubnets[*].id, count.index)
  }

  # Create an IAM role for EKS cluster
  resource "aws_iam_role" "eks_cluster" {
    name = "eks-cluster-role"
    
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "eks.amazonaws.com"
          }
        }
      ]
    })

  }

  # Attach policies to the IAM role for EKS cluster
  resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster.name
  }

  resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    role       = aws_iam_role.eks_cluster.name
  }

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceControllerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# Create an EKS cluster
resource "aws_eks_cluster" "sky_eye_eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.SkyEyeSubnets[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceControllerPolicy,
  ]
}

  resource "aws_iam_role" "worker" {
    name = "ed-eks-worker"

    assume_role_policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    })
  }

  resource "aws_iam_policy" "autoscaler" {
    name = "ed-eks-autoscaler-policy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeTags",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup",
            "ec2:DescribeLaunchTemplateVersions"
          ],
          "Effect": "Allow",
          "Resource": "*"
        }
      ]
    })
  }

  resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.worker.name
  }

  resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.worker.name
  }

  resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    role       = aws_iam_role.worker.name
  }

  resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.worker.name
  }

  resource "aws_iam_role_policy_attachment" "x-ray" {
    policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
    role       = aws_iam_role.worker.name
  }

  resource "aws_iam_role_policy_attachment" "s3" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
    role       = aws_iam_role.worker.name
  }

  resource "aws_iam_role_policy_attachment" "autoscaler" {
    policy_arn = aws_iam_policy.autoscaler.arn
    role       = aws_iam_role.worker.name
  }

  resource "aws_iam_instance_profile" "worker" {
    depends_on = [aws_iam_role.worker]
    name       = "ed-eks-worker-new-profile"
    role       = aws_iam_role.worker.name
  }

# Create an Elastic Container Registry (ECR)
resource "aws_ecr_repository" "sky_eye_ecr_repository" {
  name = var.ecr_repository_name

  image_tag_mutability = "IMMUTABLE"
}

  resource "aws_eks_node_group" "node-grp" {
    cluster_name    = aws_eks_cluster.sky_eye_eks_cluster.name
    node_group_name = "pc-node-group"
    node_role_arn   = aws_iam_role.worker.arn
    subnet_ids      = aws_subnet.SkyEyeSubnets[*].id
    capacity_type   = "ON_DEMAND"
    disk_size       = 20
    instance_types  = ["t2.small"]


    labels = {
      env = "dev"
    }

    scaling_config {
      desired_size = 2
      max_size     = 2
      min_size     = 1
    }

    update_config {
      max_unavailable = 1
    }

    depends_on = [
      aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
      aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
      aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    ]
  }
