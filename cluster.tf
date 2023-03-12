# ################################################################################
# # EMR Module
# ################################################################################

# module "emr_instance_fleet" {
#   source = "../.."

#   name = "${local.name}-instance-fleet"

#   release_label_filters = {
#     emr6 = {
#       prefix = "emr-6"
#     }
#   }
#   applications = ["spark", "hive", "hadoop", "jupyterhub"]
#   auto_termination_policy = {
#     idle_timeout = 3600
#   }

#   bootstrap_action = {
#     example = {
#       path = "file:/bin/echo",
#       name = "Just an example",
#       args = ["Hello World!"]
#     }
#   }

#   configurations_json = jsonencode([
#     {
#       "Classification" : "spark-env",
#       "Configurations" : [
#         {
#           "Classification" : "export",
#           "Properties" : {
#             "JAVA_HOME" : "/usr/lib/jvm/java-1.8.0"
#           }
#         }
#       ],
#       "Properties" : {}
#     }
#   ])

#   master_instance_fleet = {
#     name                      = "master-fleet"
#     target_on_demand_capacity = 1
#     instance_type_configs = [
#       {
#         instance_type = "m5.large"
#       }
#     ]
#   }

#   core_instance_fleet = {
#     name                      = "core-fleet"
#     target_on_demand_capacity = 0
#     target_spot_capacity      = 2
#     instance_type_configs = [
#       {
#         instance_type     = "c4.large"
#         weighted_capacity = 1
#       },
#       {
#         bid_price_as_percentage_of_on_demand_price = 100
#         ebs_config = {
#           size                 = 64
#           type                 = "gp3"
#           volumes_per_instance = 1
#         }
#         instance_type     = "c5.xlarge"
#         weighted_capacity = 2
#       },
#       {
#         bid_price_as_percentage_of_on_demand_price = 100
#         instance_type                              = "c6i.xlarge"
#         weighted_capacity                          = 2
#       }
#     ]
#     launch_specifications = {
#       spot_specification = {
#         allocation_strategy      = "capacity-optimized"
#         block_duration_minutes   = 0
#         timeout_action           = "SWITCH_TO_ON_DEMAND"
#         timeout_duration_minutes = 5
#       }
#     }
#   }

#   task_instance_fleet = {
#     name                      = "task-fleet"
#     target_on_demand_capacity = 0
#     target_spot_capacity      = 2
#     instance_type_configs = [
#       {
#         instance_type     = "c4.large"
#         weighted_capacity = 1
#       },
#       {
#         bid_price_as_percentage_of_on_demand_price = 100
#         ebs_config = {
#           size                 = 64
#           type                 = "gp3"
#           volumes_per_instance = 1
#         }
#         instance_type     = "c5.xlarge"
#         weighted_capacity = 2
#       }
#     ]
#     launch_specifications = {
#       spot_specification = {
#         allocation_strategy      = "capacity-optimized"
#         block_duration_minutes   = 0
#         timeout_action           = "SWITCH_TO_ON_DEMAND"
#         timeout_duration_minutes = 5
#       }
#     }
#   }

#   ebs_root_volume_size = 64
#   ec2_attributes = {
#     subnet_ids = data.aws_subnets.controltower.ids
#   }
#   vpc_id = module.vpc.vpc_id
#   # Required for creating public cluster
#   is_private_cluster = false

#   keep_job_flow_alive_when_no_steps = true
#   list_steps_states                 = ["PENDING", "RUNNING", "CANCEL_PENDING", "CANCELLED", "FAILED", "INTERRUPTED", "COMPLETED"]
#   log_uri                           = "s3://${module.s3_bucket.s3_bucket_id}/"

#   scale_down_behavior    = "TERMINATE_AT_TASK_COMPLETION"
#   step_concurrency_level = 3
#   termination_protection = false
#   visible_to_all_users   = true
# }