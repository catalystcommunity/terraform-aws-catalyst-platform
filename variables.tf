variable "vpc_name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type = list(object({
    az_name             = string
    private_subnet_cidr = string
    public_subnet_cidr  = string
  }))
  default = []
}

variable "enable_eks_subnet_tags" {
  type    = bool
  default = true
}

variable "eks_cluster_name" {
  type = string
}

variable "eks_cluster_version" {
  type    = string
  default = "1.22"
}

variable "eks_cluster_enabled_log_types" {
  type    = list(string)
  default = []
}

variable "eks_cluster_endpoint_private_access" {
  type    = bool
  default = false
}

variable "eks_cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "enable_eks_default_node_groups" {
  description = "enables creation of a default set of node groups, one per availability zone defined by the availability_zones variable"
  type        = bool
  default     = true
}

variable "eks_default_node_groups_version" {
  description = "Kubernetes version of the EKS cluster's default node group, allows for upgrading the kubernetes control plane first, then upgrading the node groups separately afterwards. Defaults to the specified eks_cluster_version variable."
  type        = string
  default     = ""
}

variable "eks_default_node_groups_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "eks_default_node_groups_initial_desired_size" {
  type    = number
  default = 1
}

variable "eks_default_node_groups_max_size" {
  type    = number
  default = 3
}

variable "eks_default_node_groups_min_size" {
  type    = number
  default = 1
}

variable "cluster_autoscaler_namespace" {
  type    = string
  default = "cluster-autoscaler"
}

variable "cluster_autoscaler_service_account_name" {
  type    = string
  default = "cluster-autoscaler"
}

variable "manage_aws_auth_configmap" {
  description = "Whether to manage the aws-auth configmap. Requires configuration of a Kubernetes provider."
  type        = bool
  default     = false
}

variable "aws_auth_roles" {
  description = "extra roles to add to the mapRoles field in the aws_auth configmap, for granting access via IAM roles"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_users" {
  description = "extra users to add to the mapUsers field in the aws_auth configmap, for granting access via IAM users"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_sso_roles" {
  description     = "extra SSO roles to add to the mapRoles field. Auto discovers SSO role ARNs based on regex."
  type            = list(object({
    sso_role_name = string
    username      = string
    groups        = list(string)
  }))
  default = []
}

variable "enable_velero_dependencies" {
  type    = bool
  default = true
}

variable "velero_service_account_name" {
  type    = string
  default = "velero"
}

variable "velero_namespace" {
  type    = string
  default = "velero"
}

variable "enable_loki_dependencies" {
  type    = bool
  default = false
}

variable "loki_service_account_name" {
  type    = string
  default = "loki"
}

variable "loki_namespace" {
  type    = string
  default = "loki"
}

variable "enable_cortex_dependencies" {
  type    = bool
  default = false
}

variable "cortex_service_account_name" {
  type    = string
  default = "cortex"
}

variable "cortex_namespace" {
  type    = string
  default = "cortex"
}

variable "tags" {
  type    = map(string)
  default = {}
}
