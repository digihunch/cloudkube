CommonTags={
  Environment = "Test"
  Owner       = "my@digihunch.com"
}
node_group_configs=[
  {
    name              = "myng1"
    cpu_arch          = "amd64"
    instance_type     = "t3.medium"
    ami_type          = "BOTTLEROCKET_x86_64"
    node_size_desired = 3
    node_size_min     = 3
    node_size_max     = 3
  },
  {
    name              = "myng2"
    cpu_arch          = "amd64"
    instance_type     = "t3.medium"
    ami_type          = "AL2023_x86_64_STANDARD"
    node_size_desired = 3
    node_size_min     = 3
    node_size_max     = 3
  },
  {
    name              = "myng3"
    cpu_arch          = "arm64"
    instance_type     = "m7g.large"
    ami_type          = "BOTTLEROCKET_ARM_64"
    node_size_desired = 3
    node_size_min     = 3
    node_size_max     = 3
  }
]
