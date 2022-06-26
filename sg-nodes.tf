resource "aws_security_group" "nodes-sg" {
  name        = "nodes-sg"
  description = "Workers communication with each other"
  vpc_id      = aws_vpc.eks-vpc.id

  egress {
    description      = "Allow nodes all egress to the Internet."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    self             = false
  }

  tags = {
    Name = "nodes-sg"
  }
}

resource "aws_security_group_rule" "workers-to-communicate" {
  description       = "Allow node to communicate with each other."
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nodes-sg.id
}

resource "aws_security_group_rule" "workers-to-cluster" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster-sg.id
  security_group_id        = aws_security_group.nodes-sg.id
}
#
resource "aws_security_group_rule" "workers-ssh" {
  description              = "Allow pods ssh"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes-sg.id
  source_security_group_id = aws_security_group.nodes-sg.id
}