variable "subnets" {
    type = list(string)

}

variable "vpc-id" {
    type=string

}

variable "LB-sg" {
    type=string
  }

variable "cpu-target" {

type=number
}

variable "key-pair" {
  type=string
}

variable "ami" {
  type=string
}

variable "setid" {
  type=string
  
}

variable "zoneid" {
  type=string
}

variable "record-name" {
  type = string
}
variable "failover-type" {
  type = string
}




data "aws_vpc" "data-vpc-tf" {
  id = var.vpc-id
}

resource "aws_elb" "openmrs-lb-tf" {
  subnets=var.subnets
security_groups = [var.LB-sg]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

}

resource "aws_security_group" "instance-sg-tf" {
  name = "instance-sg-tf"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.data-vpc-tf.cidr_block]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "openmrs-lc-tf" {
  image_id               = var.ami
  instance_type          = "t2.micro"
  name_prefix = "from-tf"
  security_groups        = [aws_security_group.instance-sg-tf.id]
  key_name               = var.key-pair
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install openjdk-8-jdk -y
              sudo apt-get install tomcat8 -y
              wget https://openmrsneel.s3.amazonaws.com/myapp/openmrs.war /var/lib/tomcat8/webapps/
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "cpupolicy-tf" {
  name                   = "cpupolicy-tf"
  autoscaling_group_name = aws_autoscaling_group.openmrs-acg-tf.name
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
  predefined_metric_specification {
    predefined_metric_type = "ASGAverageCPUUtilization"
  }

  target_value = var.cpu-target
}
}

resource "aws_autoscaling_attachment" "asg-attachment-tf" {
  autoscaling_group_name = aws_autoscaling_group.openmrs-acg-tf.id
  elb                    = aws_elb.openmrs-lb-tf.id
}

resource "aws_autoscaling_group" "openmrs-acg-tf" {
  launch_configuration = aws_launch_configuration.openmrs-lc-tf.id
  vpc_zone_identifier=var.subnets
  min_size = 1
  max_size = 3
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
}


resource "aws_route53_record" "www" {
  zone_id = var.zoneid
  name    = var.record-name
  type    = "A"
  set_identifier = var.setid
  failover_routing_policy {
    type= var.failover-type
  }
  alias {
    name                   = aws_elb.openmrs-lb-tf.dns_name
    zone_id                = aws_elb.openmrs-lb-tf.zone_id
    evaluate_target_health = "true"
  }
}
