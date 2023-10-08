import argparse, sys, os
from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import ECS, Fargate, AutoScaling, ECR, ElasticContainerServiceContainer, ElasticContainerServiceService 
from diagrams.aws.network import (
    VPC,
    Route53,
    CF,
    PrivateSubnet,
    PublicSubnet,
    InternetGateway,
    ALB
)
from diagrams.aws.security import WAF
from diagrams.onprem.compute import Server

#######################################################
# Setup Some Input Variables for Easier Customization #
#######################################################
title = "nginxdemo"
outformat = "png"
filename = "nginxdemo"
filenamegraph = "nginxdemo.gv"
show = False
direction = "LR"
smaller = "1"

with Diagram(
    name=title,
    direction=direction,
    show=show,
    filename=filename,
    outformat=outformat,
) as diag:
    # Non Clustered
    waf = WAF("waf")
    user = Server("user")
    dns = Route53("dns")
    cname = Route53("cname")
    cf = CF("Cloudfront CDN")
    nginx_ecr = ECR("nginxdemo-ecr")
    # Cluster = Group, so this outline will group all the items nested in it automatically
    with Cluster("AWS Region"):
        with Cluster("nginx-demo-vpc"):
            vpc = VPC("nginx-demo-vpc")
            igw_gateway = InternetGateway("igw")  
            lb = ALB("App load balancer")   
            
            with Cluster("ECS"):
                nginx_ecs = ECS("nginx_ecs")
                nginx_ecs_service = ElasticContainerServiceService("ecs_service")
                with Cluster("ecs_autoscaling"):
                    nginx_ecs_autoscaling = AutoScaling("nginx_ecs_autoscaling")
                    with Cluster("az1"):
                        with Cluster("Farget"):
                            fargate_1 = Fargate("Farget_az1")
                            taskaz1 = ElasticContainerServiceContainer("tasks")
                
                    with Cluster("az2"):            
                        with Cluster("Farget"):
                            fargate_2 = Fargate("Farget_az2")
                            taskaz2 = ElasticContainerServiceContainer("tasks")

                    with Cluster("az3"):            
                        with Cluster("Farget"):
                            fargate_3 = Fargate("Farget_az3")
                            taskaz3 = ElasticContainerServiceContainer("tasks")
        
    fargate_group = [fargate_1, fargate_2, fargate_3]
    tasks_group = [taskaz1, taskaz2, taskaz3]
    # Now I document the flow here for clarity
    # Could do it in each node area, but I like the "connection flow" to be at the bottom
    ###################################################
    # FLOW OF ACTION, NETWORK, or OTHER PATH TO CHART #
    ################################################### 
    waf >> cf
    user >> dns >> cf >> cname>>  lb
    lb - Edge(color="black", style="bold") >> fargate_group
    nginx_ecr - Edge(color="brown", style="normal") >> fargate_group
    nginx_ecs_service - Edge(color="blue", style="bold") >> fargate_group
diag