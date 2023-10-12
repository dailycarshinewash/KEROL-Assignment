provider "aws" {
  region = var.region

  default_tags {
    tags = {
      owner   = "suyog maid"
      Project = var.project_name
    }
  }
}

# ECR
module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "${var.project_name}-ecr"
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECS Cluster

resource "aws_ecs_cluster" "default" {
  name = "${var.project_name}-fg"
}

# Container Definition
module "container_definition" {
  source                       = "cloudposse/ecs-container-definition/aws"
  version                      = "0.60.1"
  container_name               = var.container_name
  container_image              = var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = var.container_cpu
  essential                    = var.container_essential
  readonly_root_filesystem     = var.container_readonly_root_filesystem
  environment                  = var.container_environment
  port_mappings                = var.container_port_mappings
}

# ALB
module "alb" {
  source = "cloudposse/alb/aws"

  namespace                         = "eg"
  stage                             = "prod"
  name                              = var.project_name
  attributes                        = ["public"]
  delimiter                         = "-"
  vpc_id                            = var.vpc_id
  security_group_ids                = var.security_group_ids
  subnet_ids                        = var.subnet_ids
  internal                          = false
  http_enabled                      = true
  http_redirect                     = false
  access_logs_enabled               = true
  cross_zone_load_balancing_enabled = false
  http2_enabled                     = true
  idle_timeout                      = 60
  ip_address_type                   = "ipv4"
  deletion_protection_enabled       = false
  deregistration_delay              = 15
  health_check_path                 = "/"
  health_check_timeout              = 10
  health_check_healthy_threshold    = 2
  health_check_unhealthy_threshold  = 2
  health_check_interval             = 15
  health_check_matcher              = "200"
  target_group_port                 = 80
  target_group_target_type          = "ip"
  stickiness = {
    cookie_duration = 60
    enabled         = true
  }

  alb_access_logs_s3_bucket_force_destroy = true

}

# alb_ingress
module "alb_ingress" {
  source = "cloudposse/alb-ingress/aws"
  # Cloud Posse recommends pinning every module to a specific version
  # version     = "x.x.x"

  namespace                     = "eg"
  stage                         = "prod"
  name                          = var.project_name
  attributes                    = ["public"]
  delimiter                     = "-"
  vpc_id                        = var.vpc_id
  authentication_type           = ""
  unauthenticated_priority      = 100
  unauthenticated_paths         = ["/*"]
  default_target_group_enabled  = false
  target_group_arn              = module.alb.default_target_group_arn
  unauthenticated_listener_arns = [module.alb.http_listener_arn]
}

#ecs_service_task
module "ecs_alb_service_task" {
  source = "cloudposse/ecs-alb-service-task/aws"

  namespace                          = "eg"
  stage                              = "prod"
  name                               = "bastion"
  attributes                         = ["publics"]
  delimiter                          = "-"
  alb_security_group                 = module.alb.security_group_id
  container_definition_json          = module.container_definition.json_map_encoded_list
  ecs_cluster_arn                    = aws_ecs_cluster.default.arn
  launch_type                        = "FARGATE"
  vpc_id                             = var.vpc_id
  security_group_ids                 = var.security_group_ids
  subnet_ids                         = var.subnet_ids
  ignore_changes_task_definition     = false
  network_mode                       = "awsvpc"
  assign_public_ip                   = false
  propagate_tags                     = "TASK_DEFINITION"
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_controller_type         = "ECS"
  desired_count                      = var.desired_count
  task_memory                        = var.task_memory
  task_cpu                           = var.task_cpu

  ecs_load_balancers = [{
    container_name   = var.container_name
    container_port   = 80
    elb_name         = null
    target_group_arn = module.alb.default_target_group_arn
  }]
}
