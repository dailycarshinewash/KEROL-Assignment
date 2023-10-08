import argparse, sys, os
from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import ECS, Fargate, EC2, AutoScaling, ECR, ElasticContainerServiceContainer 
from diagrams.aws.network import (
    VPC,
    Route53,
    PrivateSubnet,
    PublicSubnet,
    InternetGateway,
    ALB,
    NATGateway
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
smaller = "0.8"


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
    
    nginx_ecr = ECR("nginxdemo-ecr")
    # Cluster = Group, so this outline will group all the items nested in it automatically
    with Cluster("vpc"):
        vpc = VPC("nginx-demo-vpc")
        igw_gateway = InternetGateway("igw")  
        lb = ALB("App load balancer")   
        
        with Cluster("az1"):
            with Cluster("Farget"):
                fargate_1 = Fargate("Farget_az1")
                taskaz1 = ElasticContainerServiceContainer("tasks")
       
        with Cluster("az2"):            
            with Cluster("Farget"):
                fargate_2 = Fargate("Farget_az2")
                taskaz1 = ElasticContainerServiceContainer("tasks")

        with Cluster("az3"):            
            with Cluster("Farget"):
                fargate_3 = Fargate("Farget_az3")
                taskaz1 = ElasticContainerServiceContainer("tasks")
       
    fargate_group = [fargate_1, fargate_2, fargate_3]

    # Now I document the flow here for clarity
    # Could do it in each node area, but I like the "connection flow" to be at the bottom
    ###################################################
    # FLOW OF ACTION, NETWORK, or OTHER PATH TO CHART #
    ################################################### 
    user >> dns >> waf >> igw_gateway >> lb
    lb - Edge(color="black", style="bold") >> fargate_group
    nginx_ecr - Edge(color="brown", style="dotted") >> fargate_group

diag