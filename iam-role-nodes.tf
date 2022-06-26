resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = <<POLICY
{
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
}
POLICY
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_instance_profile" "eks-node" {
  name = "eks-node"
  role = aws_iam_role.nodes.name
}

resource "aws_launch_template" "lt-eks-dev" {
  name          = "lt-eks-dev"
  image_id      = "ami-098e2d2d225d29caf"
  instance_type = "t3.medium"
  user_data = base64encode(templatefile("./user-d.sh", {
    cluster_name = var.cluster_name
    node_labels  = var.node_labels
  }))
  vpc_security_group_ids = [aws_security_group.cluster-sg.id, aws_security_group.nodes-sg.id]
  iam_instance_profile {
    arn = aws_iam_instance_profile.eks-node.arn
  }
}

resource "aws_autoscaling_group" "asg_ec2" {
  capacity_rebalance  = true
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public-us-east-1a.id, aws_subnet.public-us-east-1b.id, aws_subnet.public-us-east-1c.id]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 25
      spot_allocation_strategy                 = "capacity-optimized"
    }

  launch_template {
    launch_template_specification {
      launch_template_id = aws_launch_template.lt-eks-dev.id
    }
   }
  }

  tags = concat(
    [
      for tag, value in var.tags : {
        key                 = tag
        value               = value
        propagate_at_launch = true
      }
    ],
    [
      {
        key                 = "Name"
        value               = "eks-dev"
        propagate_at_launch = true
      },
      {
        key                 = "kubernetes.io/cluster/eks-dev"
        value               = "owned"
        propagate_at_launch = true
      },
    ]
  )
    
   depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ] 
}

  





 


