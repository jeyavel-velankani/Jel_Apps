# Topics to explore

Explore these topics and understand how to implement a basic version.


# Amazon Elastic Beanstalk and Opswork
Creating an AWS Elastic Beanstalk Environment http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.environments.html

AWS OpsWorks and AWS Elastic Beanstalk both automate operations but serve different needs and purposes. AWS Elastic Beanstalk is designed for developers who want to deploy web applications without worrying about operations. Developers simply upload their code and Elastic Beanstalk automatically handles the deployment, from capacity provisioning, load balancing, auto-scaling to application health monitoring. The application will be ready to use without any infrastructure or resource configuration work on the developer’s part.

In contrast, AWS OpsWorks is an integrated configuration management platform for IT administrators and DevOps engineers who want a high degree of customization and control over operations. AWS OpsWorks users leverage Chef recipes to automate operations like software configurations, package installations, database setups, server scaling, and code deployment.


From https://www.quora.com/Why-would-you-choose-Elastic-Beanstalk-over-OpsWorks-or-vice-versa:
Think of Elastic Beanstalk as the simplest way to get a scalable web application up and running. A lot of the intricacies are taken care of for you and all you really need to get started is an understanding of the required file structure. .ebextensions allow you to easily customize your server and setup cron jobs. I use EB all the time because it is just that simple.

OpsWorks takes automatic deployment to the next level of complexity for those that want complete control over their deployments and need to be able to tweak/configure everything.

If you are a beginner, get your feet wet with EB and when you need something more powerful like OpsWorks, it will be obvious.

Elastic Beanstalk is aimed more at developers of simple three-tier apps, while OpsWorks gives you more options and leverages Chef for CM.

# Cloudwatch

# AWS RDS - how to use mysql with this
# DynamoDB
