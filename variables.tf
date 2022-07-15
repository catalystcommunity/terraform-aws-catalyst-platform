variable "vpc_name" {
  description = "Name of the VPC to create. Used in VPC resource tags for naming."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability zones with corresponding public and private subnet CIDRs to create subnets in each. Default EKS node groups get created for each availability zone specified."
  type = list(object({
    az_name             = string
    private_subnet_cidr = string
    public_subnet_cidr  = string
  }))
  default = []
}

variable "enable_eks_subnet_tags" {
  description = "Whether to enable addition of EKS tags to subnet resources."
  type        = bool
  default     = true
}

variable "eks_cluster_name" {
  description = "Name of EKS cluster. Used in naming of many EKS resources, including cluster, IAM roles and policies, S3 buckets for Velero, Cortex, Loki, etc."
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  type        = string
  default     = "1.22"
}

variable "eks_cluster_enabled_log_types" {
  description = "List of EKS log types to enable."
  type        = list(string)
  default     = []
}

variable "eks_cluster_endpoint_private_access" {
  description = "Whether to enable private VPC access to the k8s API."
  type        = bool
  default     = false
}

variable "eks_cluster_endpoint_public_access" {
  description = "Whether to enable public internet access to the k8s API."
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "What CIDRs to allow public access from to the k8s API."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_eks_default_node_groups" {
  description = "Enables creation of a default set of node groups, one per availability zone defined by the availability_zones variable"
  type        = bool
  default     = true
}

variable "eks_default_node_groups_version" {
  description = "Kubernetes version of the EKS cluster's default node groups, allows for upgrading the kubernetes control plane first, then upgrading the node groups separately afterwards. Defaults to the specified eks_cluster_version variable."
  type        = string
  default     = ""
}

variable "eks_default_node_groups_instance_types" {
  description = "EC2 instance types to configure the default node groups with."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_default_node_groups_initial_desired_size" {
  description = "Default node groups' initial desired size. Changes to this field are ignored to prevent downscaling during terraform updates."
  type        = number
  default     = 1
}

variable "eks_default_node_groups_max_size" {
  description = "Default node groups' maximum size."
  type        = number
  default     = 3
}

variable "eks_default_node_groups_min_size" {
  description = "Default node groups' minimum size"
  type        = number
  default     = 1
}

variable "cluster_autoscaler_namespace" {
  description = "Cluster autoscaler namespace, for configuring IRSA."
  type        = string
  default     = "cluster-autoscaler"
}

variable "cluster_autoscaler_service_account_name" {
  description = "Cluster autoscaler service account name, for configuring IRSA."
  type        = string
  default     = "cluster-autoscaler"
}

variable "manage_aws_auth_configmap" {
  description = "Whether to manage the aws-auth configmap. Requires configuration of a Kubernetes provider."
  type        = bool
  default     = false
}

variable "aws_auth_roles" {
  description = "Extra roles to add to the mapRoles field in the aws_auth configmap, for granting access via IAM roles"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_users" {
  description = "Extra users to add to the mapUsers field in the aws_auth configmap, for granting access via IAM users"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_sso_roles" {
  description = "Extra SSO roles to add to the mapRoles field. Auto discovers SSO role ARNs based on regex."
  type = list(object({
    sso_role_name = string
    username      = string
    groups        = list(string)
  }))
  default = []
}

variable "enable_velero_dependencies" {
  description = "Whether to enable Velero S3 bucket and IAM role with IRSA."
  type        = bool
  default     = true
}

variable "velero_bucket_name_override" {
  description = "Override the Velero bucket name"
  type        = string
  default     = ""
}

variable "create_velero_bucket" {
  description = "Whether to create the Velero bucket when Velero dependencies are enabled. Allows for disabling the bucket and still creating the IAM dependencies, for scenarios where the bucket is not managed by terraform such as disaster recovery"
  type        = bool
  default     = true
}

variable "velero_namespace" {
  description = "Velero namespace, for configuring IRSA."
  type        = string
  default     = "velero"
}

variable "velero_service_account_name" {
  description = "Velero service account name, for configuring IRSA."
  type        = string
  default     = "velero"
}

variable "enable_loki_dependencies" {
  description = "Whether to enable Loki S3 bucket and IAM role with IRSA."
  type        = bool
  default     = false
}

variable "loki_bucket_name_override" {
  description = "Override the Loki bucket name"
  type        = string
  default     = ""
}

variable "create_loki_bucket" {
  description = "Whether to create the Loki bucket when Loki dependencies are enabled. Allows for disabling the bucket and still creating the IAM dependencies, for scenarios where the bucket is not managed by terraform such as disaster recovery"
  type        = bool
  default     = true
}

variable "loki_namespace" {
  description = "Loki namespace, for configuring IRSA."
  type        = string
  default     = "loki"
}

variable "loki_service_account_name" {
  description = "Loki service account name, for configuring IRSA."
  type        = string
  default     = "loki"
}

variable "enable_cortex_dependencies" {
  description = "Whether to enable Cortex S3 bucket and IAM role with IRSA."
  type        = bool
  default     = false
}

variable "cortex_bucket_name_override" {
  description = "Override the Cortex bucket name"
  type        = string
  default     = ""
}

variable "create_cortex_bucket" {
  description = "Whether to create the Cortex bucket when Cortex dependencies are enabled. Allows for disabling the bucket and still creating the IAM dependencies, for scenarios where the bucket is not managed by terraform such as disaster recovery"
  type        = bool
  default     = true
}

variable "cortex_namespace" {
  description = "Cortex namespace, for configuring IRSA."
  type        = string
  default     = "cortex"
}

variable "cortex_service_account_name" {
  description = "Cortex service account name, for configuring IRSA."
  type        = string
  default     = "cortex"
}

variable "create_cloudwatch_synthetics_bucket" {
  description = "Whether to create an S3 bucket for CloudWatch Synthetics."
  type        = bool
  default     = false
}

variable "cloudwatch_synthetics_bucket_name_override" {
  description = "Override the CloudWatch Synthetics bucket name."
  type        = string
  default     = ""
}

variable "cloudwatch_synthetics_canaries" {
  description = "List of CloudWatch Synthetic Canaries to create. Name is required, all other fields will inherit defaults if set to null."
  type = list(object({
    name                  = string
    artifact_s3_location  = string
    handler               = string
    runtime_version       = string
    source_code_path      = string
    environment_variables = map(string)
    delete_lambda         = bool
    timeout_in_seconds    = number
    schedule_expression   = string
  }))
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
