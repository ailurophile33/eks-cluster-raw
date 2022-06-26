#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-dev.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-dev.certificate_authority.0.data}' 'eks-dev'
USERDATA