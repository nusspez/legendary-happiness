from email.policy import Policy
from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_iam as iam,
    aws_s3_assets as s3_assets,
    aws_elasticloadbalancingv2 as elb,
    aws_autoscaling as autoscaling,
)

import aws_cdk as core
from constructs import Construct

class CdkStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # use the default vpc 
        VPC = ec2.Vpc.from_lookup(self,"VpcId",is_default=True)

        # create the pair key

        PAIR_KEY = ec2.CfnKeyPair(self, "EC2CfnKeyPair", key_name="ec2-key")


        # create the security group for the ec2

        SECURITY_GROUP_EC2 = ec2.SecurityGroup(self, "SecurityGroupEc2",
                                                vpc=VPC,
                                                allow_all_outbound=True)

        # allow the port 22

        SECURITY_GROUP_EC2.add_ingress_rule(ec2.Peer.any_ipv4(), ec2.Port.tcp(22), "Permite el acceso SSH ")
    
        # allow port 80 of app

        SECURITY_GROUP_EC2.add_ingress_rule(ec2.Peer.any_ipv4(), ec2.Port.tcp(80), "Permite el acceso al puerto 80 ")

        #  IAM role to allow access to other AWS services

        EC2_ROLE = iam.Role(self, "EC2IamRole", assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"))

        # IAM policy to the role

        EC2_ROLE.add_managed_policy(iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedInstanceCore"))

        # define the AMI for the EC2 instance 

        EC2_AMI = ec2.AmazonLinuxImage(cpu_type=ec2.AmazonLinuxCpuType.X86_64, generation= ec2.AmazonLinuxGeneration.AMAZON_LINUX_2)

        # create the aws ec2 instance

        # EC2_INSTANCE = ec2.Instance(self,"NginxInstance", 
        #                             vpc = VPC, 
        #                             instance_type=ec2.InstanceType.of(instance_class=ec2.InstanceClass.BURSTABLE2, instance_size=ec2.InstanceSize.MICRO),
        #                             machine_image=EC2_AMI,
        #                             security_group=SECURITY_GROUP_EC2,
        #                             key_name="ec2-key",
        #                             role=EC2_ROLE,                                
        #                             )
        
        # install the nginx server

        # create user data

        USER_DATA=ec2.UserData.for_linux();

        USER_DATA.add_commands('yum update -y',
                                            'sudo su',
                                            'amazon-linux-extras install -y nginx1',
                                            'systemctl start nginx',
                                            'systemctl enable nginx',
                                            'chmod 2775 /usr/share/nginx/html',
                                            'find /usr/share/nginx/html -type d -exec chmod 2775 {} \;',
                                            'find /usr/share/nginx/html -type f -exec chmod 0664 {} \;',
                                            'echo "<h1>It worked</h1>" > /usr/share/nginx/html/index.html'
                                    )

        # add the load balancer and listener

        EC2_ELB = elb.ApplicationLoadBalancer(self,"Ec2Elb",vpc=VPC, internet_facing=True, load_balancer_name="NginxELB")

        EC2_LISTENER_ELB = EC2_ELB.add_listener("lsitener",port=80, open=True)

        # create Auto Scalling Group

        AUTO_SCALING_GROUP = autoscaling.AutoScalingGroup(self,"AutoScalingGroupEc2",
                                                            vpc=VPC,
                                                            instance_type=ec2.InstanceType.of(instance_class=ec2.InstanceClass.BURSTABLE2, instance_size=ec2.InstanceSize.MICRO),
                                                            machine_image=EC2_AMI,
                                                            key_name="ec2-key",
                                                            role=EC2_ROLE,
                                                            user_data=USER_DATA,
                                                            min_capacity=1,
                                                            max_capacity=2
                                                            )

        # add target to the ALb listener

        EC2_LISTENER_ELB.add_targets("ec2-target",
                                    port=80,
                                    targets=[AUTO_SCALING_GROUP],
                                    health_check=elb.HealthCheck(path='/', unhealthy_threshold_count=2, healthy_threshold_count=5, interval=core.Duration.seconds(30)))


        # add acction to the elb listener

        EC2_LISTENER_ELB.add_action('redirect', priority=5,
                                     conditions= [elb.ListenerCondition.path_patterns(['/static'])],
                                     action= elb.ListenerAction.fixed_response(status_code=200, 
                                                                                content_type='text/html',
                                                                                message_body='<h1>Static ALB Response</h1>')
                                     )
        # add scaling policy

        AUTO_SCALING_GROUP.scale_on_request_count('requests-per-minute',target_requests_per_minute=60)

        # add scaling policy for the autoscaling group

        AUTO_SCALING_GROUP.scale_on_cpu_utilization('cpu-util-scaling',target_utilization_percent=75)

        # at the emd chekout the DNS lb
        
        core.CfnOutput(self, "DNS",value=EC2_ELB.load_balancer_dns_name)
         