##### APPLICATION LOAD BALANCER #####
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "main-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "app-target-group"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

#### LAUNCH TEMPLATE #####
resource "aws_launch_template" "app" {
  name_prefix   = "wordpress-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_core
  ]

  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = base64encode(local.primary_user_data)

  # Require IMDSv2 for instance metadata access
  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "wordpress-app-server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


##### AUTO SCALING GROUP #####
resource "aws_autoscaling_group" "app" {
  name                = "wordpress-app-sg"
  min_size            = 2
  desired_capacity    = 2
  max_size            = 4
  vpc_zone_identifier = [aws_subnet.private_app_a.id, aws_subnet.private_app_b.id]
  target_group_arns   = [aws_lb_target_group.app.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  depends_on = [aws_efs_mount_target.app_a, aws_efs_mount_target.app_b]

  tag {
    key                 = "Name"
    value               = "wordpress-app-server"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}


##### AUTO SCALING POLICY #####
resource "aws_autoscaling_policy" "app_cpu" {
  name                   = "wordpress-app-cpu-scaling"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}
