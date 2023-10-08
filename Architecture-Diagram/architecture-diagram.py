import argparse, sys, os
from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import ECS, Fargate, EC2, AutoScaling
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
    

    # Cluster = Group, so this outline will group all the items nested in it automatically
    with Cluster("vpc"):
        vpc = VPC("nginx-demo-vpc")
        igw_gateway = InternetGateway("igw")  
        lb = ALB("App load balancer")   
        
        with Cluster("az1"):          
            auto_scaling_group = AutoScaling("auto scaling group")
  
            # Subcluster for grouping inside the vpc
            with Cluster("public_subnet_1"):                
                public_subnet_1 = PublicSubnet("public-subnet-1")
                nat_gateway_1 = NATGateway("nat_gateway_1")
                bastion_server = EC2("Bastion Host")
            # Another subcluster equal to the subnet one above it
            with Cluster("private_subnet_1"):
                private_subnet_1 = PrivateSubnet("private-subnet-1") 
                # ec2_server_app_server = EC2("app_server")
                # ec2_server_image_processing = EC2("async_image_processing")
       
        with Cluster("az2"):            
            # Subcluster for grouping inside the vpc
            with Cluster("public_subnet_2"):
                public_subnet_2 = PublicSubnet("public-subnet-2")
                # ec2_server_web_server = EC2("web_server")
            # Another subcluster equal to the subnet one above it
            with Cluster("private_subnet_2"):
                private_subnet_2 = PrivateSubnet("private-subnet-2")
                # ec2_server_app_server = EC2("app_server")
                # ec2_server_image_processing = EC2("async_image_processing")

        with Cluster("az3"):            
            # Subcluster for grouping inside the vpc
            with Cluster("public_subnet_3"):
                public_subnet_3 = PublicSubnet("public-subnet-3")
                # ec2_server_web_server = EC2("web_server")
            # Another subcluster equal to the subnet one above it
            with Cluster("private_subnet_3"):
                private_subnet_3 = PrivateSubnet("private-subnet-3") 
                # ec2_server_app_server = EC2("app_server")
                # ec2_server_image_processing = EC2("async_image_processing")
       
        public_subnets_groups = [public_subnet_1, public_subnet_2, public_subnet_3]
        private_subnets_groups = [private_subnet_1, private_subnet_2, private_subnet_3]

    # Now I document the flow here for clarity
    # Could do it in each node area, but I like the "connection flow" to be at the bottom
    ###################################################
    # FLOW OF ACTION, NETWORK, or OTHER PATH TO CHART #
    ###################################################
    user >> dns >> waf >> igw_gateway >> lb >> public_subnets_groups
    # igw_gateway >> bastion_server 
    # bastion_server >> public_subnets_groups
    # bastion_server >> private_subnets_groups
    # nat_gateway_1 >> private_subnets_groups
diag