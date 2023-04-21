*TASK-7 (week 8): Using Load Balancer and Autoscaling Group*
  
# Load balancer and autoscaling group  
***
Week's 8 task 7 can be found [here](https://github.com/allops-solutions/devops-aws-mentorship-program/issues/52). In short:  
- [x] IAM User 1 needs to create resources inside `eu-central-1` region. (required tags for these would be `Name`, `CreatedBy` and `Email`)  
- [x] AWS owners / IAM user 1 update permissions for IAM user 2 by adding him/her to `Administrators` group  
- [x] Create [custom AMI](#create-ami). 
- [x] Create [Load balancer](#create-load-balancer) and connect it to target group.
- [x] Create [Autoscaling group]() with MIN 2 and MAX 4 instances.
- [x] Modify [security groups](#modifying-security-groups) to allow just needed ports.  
- [x] Create free account either on draw.io or lucidchart.com and make a diagram of infrastructure as you understand it.  
- [x] Simulate High availability by terminating your instances.
- [x] Simulate CPU load by following this [tutorial](https://www.wellarchitectedlabs.com/performance-efficiency/100_labs/100_monitoring_linux_ec2_cloudwatch/5_generating_load/).  

  
## Create AMI 
 Steps to create AMI:
  1. Go to `Instances`  
  2. Select image you want to create AMI from  
  3. `Actions` dropdown menu -> `Image and templates` -> `Create image`  
  4. `Create image` steps:  
     - Image name: `ami-name-lastname-web-server`  
     - Image description: AMI image created from EC2 instance in week 7 for week 8  
     - Enable reboot [x]: if ticked, instance won't restart during AMI's creation.
     - Storage: leave as it is.
     - Add new tag: add tags as needed.  
     - `Create image`

After AMI is created, you're free to terminate your EC2 instance.
  
## Create new instaces from AMI  
  1. Select AMI
  2. `Launch instance from AMI`  
  3. Launch an instance steps:  
     - Name: `ec2-web-server`  
     - Application and OS images: your AMI is already selected  
     - Instance type: `t2.micro`  
     - Key pair: use existing
     - Network settings: use security group created in previous task.
     - Configure storage: leave offered 8 GiB.  
     - `Launch instance`  


## Create Load balancer  
  1. `Load balancers`  
  2. `Create load balancer`  
  3. Application Load Balancer - `Create`  
     - Load balancer name: `alb-web-server`
     - Scheme: Internet-facing (to be accessible over internet)  
     - IP address type: IPv4  
     - Network mapping: 
       - VPC: default
       -Mappings: tick [x] `eu-central-1a` and `eu-central-1b`
     - Security groups: 
         1. `Create new security group`:
            - Basic details: 
               - Security group name: `alb-sg-web-server`
               - Description: Security group for ALB for Web servers
               - VPC: default
            - Inbound rules: add `SSH` and `HTTP`, set Source to Anywhere
            - `Create security group`
         2. Add new security group
         3. Delete default sec group
      - Listeners and routing:
      --->  1. `Create target group`:  
            -- Choose a target type: `Instances`
            -- Target group name: `tg-web-servers`
            -- Protocol: HTTP on port 80
            -- VPC: default
            -- Protocol version: HTTP1
            -- Health check protocol: HTTP
            -- Health check path: leave empty (usually here you insert path to index.html)
            -- Advanced health check settings: Port -> [x] Override (80)
            -- `Next`
      --->      2. Available instances:
            -- select planned EC2 instances
            -- Ports for the selected instances: we'll use just port 80;
            -- `Include as pending below`
            -- `Create target group`    

  
         Back on Listeners and routing:
         - Default action: select newly created target group
         - `Create load balancer`

## Modifying security groups  
As Load balancer is up and running, it's time to change inbound rules for previous security group. Steps:
   1. `Security groups`
   2. Select security group `sec-group-web-server`
   3. `Actions` -> `Edit inbound rules`
   4. Delete rule for `HTTP`
   5. `Add rule`
   6. Select `HTTP`, Custom, choose `alb-sg-web-server` and in Description field type that it's allowing traffic only from ALB
   7. `Save rules`

## Create Auto scaling group  
To create Auto scaling group, first you need to create template. Steps:
   1. `Launch Configuration`
   2. `Create launch configuration`
   3. `Create launch template`
   4. Launch template name: `asg-template-web-server`
   5. Template version description: Template for ASG used for Web server
   6. Application and OS Images (Amazon Machine Image): `My AMIs` -> `Owned by me` and select AMI you created for this purpose.
   7. Instance type: `t2.micro` (free tier)
   8. Key pair: use existing
   9. Network settings: use existing, from week 7 (`sec-group-web-server`)
   10. EBS Volumes: leave it as it is.
   11. `Create launch template`
  
After template is created, we can proceed to create Auto scale group. Steps:
   1. `Auto Scaling Groups`
   2. `Create Auto Scaling group`
   3. Name: asg-web-servers
   4. Launch template: choose template you crated before (in this case `asg-template-web-server`)
   5. Version: Latest (best choice, to be sure you're always up-to-date)
   6. `Next`
   7. VPC: Default
   8. Availability Zones and subnets: choose as planned (in this case `eu-central-1a` and `eu-central-1b`)
   9. `Next`
   10. Load balancing: `Attach to an existing load balancer`
   11. Attach to an existing load balancer: `Choose from your load balancer target groups`
   12. Existing load balancer target groups: select `tg-web-servers`
   13. Health checks: [x] tick Turn on Elastic Load Balancing health checks
   14. Health check grace period: 300 seconds
   15. Additional Settings: [x] tick Enable group metrics collection within CloudWatch
   16. `Next`
   17. Group size:  
   - Desired capacity: 3
   - Minimum capacity: 2
   - Maximum capacity: 4
   18. Scaling policies: `Target tracking scaling policy`
   19. Scaling policy name: Target Tracking Policy
   20. Mteric type: Average CPU utilization
   21. Target value: 18 (as we want to lauch new instance when CPU goes over 18%)
   22. Instance need: 0 seconds to warmup (we'll skip warming up)
   23. `Next`
   24. Add Notifications: `Add`
   25. SNS Topic: `asg-sns-notification`
   26. `Next`
   27. Tags: add tags
   28. `Next`
   29. `Create Auto Scaling group`
