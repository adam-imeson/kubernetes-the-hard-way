variable "region" {
  type = string
  default = "us-west-2"
}

variable "username" {
  type        = string
  description = "Your username - will be prepended to most resource names to track what's yours."
  default = "kubeboot"
}
