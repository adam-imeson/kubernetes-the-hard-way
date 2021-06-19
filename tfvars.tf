variable "region" {
  type = string
  default = "us-west-2"
}

variable "username" {
  type        = string
  description = "Your username - will be prepended to most resource names to track what's yours."
  default = "kubeboot"
}

variable "instance_count" {
  type = number
  description = "The number of worker nodes and the number of controller nodes to launch."
  default = 3
}
