locals {
  # for vpc
  region_az_1 = coalesce(data.aws_availability_zones.available.names...)
  region_az_2 = coalesce(setsubtract(data.aws_availability_zones.available.names, [local.region_az_1])...)

  # for tls
  ca_key_algorithm = "RSA"
  country = "US"
  locality = "Seattle"
  province = "Washington"
  key_directory = "keys"
}
