Homework for week-7:

    1) As IAM User1, create resource under `eu-central-1` region,
    2) Every AWS resource created needs to have, besides `Name` tag, `CreatedBy: name and last name` and `Email: user@email.com` tags,
    3) Update IAM user account with adding MFA device
    4) Create EC2 instance of type `t2.micro` using AMI Image `Amazon Linux 2023` with next properties:
        - Name `ec2-name-lastname-web-server`
        - Security group named `sec-group-web-server` with inbound rules accepting all traffic on ports `22` and `80`
        - Key pair name `name-lastname-web-server-key`
        - EBS volume size `14GiB` `gp3`
    5) On EC2 instance deploy `nodejs-simple-app` available on [nodejs-simple-app](https://github.com/allops-solutions/nodejs-simple-app)
    6) Make screenshots after deploying app and make sure it's visible that it was accessed using public IP address