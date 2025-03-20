# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM role for ECS execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-execution-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create a custom policy for CloudWatch Logs permissions
resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-logs-policy"
  description = "Policy for CloudWatch Logs access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the CloudWatch Logs policy to the execution role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

# IAM role for ECS tasks
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "rabbitmq" {
  name              = "/ecs/${var.project_name}-${var.environment}/rabbitmq"
  retention_in_days = 30
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-rabbitmq-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "user_service" {
  name              = "/ecs/${var.project_name}-${var.environment}/user-service"
  retention_in_days = 30
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-user-service-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "location_service" {
  name              = "/ecs/${var.project_name}-${var.environment}/location-service"
  retention_in_days = 30
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-location-service-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "review_service" {
  name              = "/ecs/${var.project_name}-${var.environment}/review-service"
  retention_in_days = 30
  
  tags = {
    Name        = "${var.project_name}-${var.environment}-review-service-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create RDS instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.project_name}-${var.environment}-postgres"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.postgres15"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
  db_name                = var.db_name

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ALB Target Groups
resource "aws_lb_target_group" "user_service" {
  name        = "${var.project_name}-${var.environment}-user-tg"
  port        = var.service_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/Health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "location_service" {
  name        = "${var.project_name}-${var.environment}-location-tg"
  port        = var.service_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/Health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-location-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "review_service" {
  name        = "${var.project_name}-${var.environment}-review-tg"
  port        = var.service_container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/Health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-review-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# Listener Rules
resource "aws_lb_listener_rule" "user_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/users*", "/api/auth*"]
    }
  }
}

resource "aws_lb_listener_rule" "location_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.location_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/locations*"]
    }
  }
}

resource "aws_lb_listener_rule" "review_service" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.review_service.arn
  }

  condition {
    path_pattern {
      values = ["/api/reviews*"]
    }
  }
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "${var.project_name}-${var.environment}-rabbitmq"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_cpu
  memory                   = var.service_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "rabbitmq"
      image     = "${data.aws_ecr_repository.repositories["deploy/rabbit"].repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = var.rabbitmq_container_port
          hostPort      = var.rabbitmq_container_port
          protocol      = "tcp"
        },
        {
          containerPort = var.rabbitmq_management_port
          hostPort      = var.rabbitmq_management_port
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "RABBITMQ_DEFAULT_USER"
          value = "guest"
        },
        {
          name  = "RABBITMQ_DEFAULT_PASS"
          value = "guest"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.rabbitmq.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-rabbitmq"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_task_definition" "user_service" {
  family                   = "${var.project_name}-${var.environment}-user-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_cpu
  memory                   = var.service_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "user-service"
      image     = "${data.aws_ecr_repository.repositories["deploy/userservice"].repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = var.service_container_port
          hostPort      = var.service_container_port
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        },
        {
          name  = "ASPNETCORE_HTTP_PORTS"
          value = "8080"
        },
        {
          name  = "ConnectionStrings__DefaultConnection"
          value = "Host=${aws_db_instance.postgres.address};Port=${aws_db_instance.postgres.port};Database=${aws_db_instance.postgres.db_name};Username=${aws_db_instance.postgres.username};Password=${aws_db_instance.postgres.password}"
        },
        {
          name  = "Jwt__Key"
          value = "YourSuperSecretKey12345678901234567890"
        },
        {
          name  = "Jwt__Issuer"
          value = "MicroservicesApp"
        },
        {
          name  = "Jwt__Audience"
          value = "MicroservicesClient"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.user_service.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_task_definition" "location_service" {
  family                   = "${var.project_name}-${var.environment}-location-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_cpu
  memory                   = var.service_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "location-service"
      image     = "${data.aws_ecr_repository.repositories["deploy/locationservice"].repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = var.service_container_port
          hostPort      = var.service_container_port
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        },
        {
          name  = "ASPNETCORE_HTTP_PORTS"
          value = "8080"
        },
        {
          name  = "ConnectionStrings__DefaultConnection"
          value = "Host=${aws_db_instance.postgres.address};Port=${aws_db_instance.postgres.port};Database=${aws_db_instance.postgres.db_name};Username=${aws_db_instance.postgres.username};Password=${aws_db_instance.postgres.password}"
        },
        {
          name  = "Jwt__Key"
          value = "YourSuperSecretKey12345678901234567890"
        },
        {
          name  = "Jwt__Issuer"
          value = "MicroservicesApp"
        },
        {
          name  = "Jwt__Audience"
          value = "MicroservicesClient"
        },
        {
          name  = "RabbitMq__HostName"
          value = aws_service_discovery_service.rabbitmq.name
        },
        {
          name  = "RabbitMq__UserName"
          value = "guest"
        },
        {
          name  = "RabbitMq__Password"
          value = "guest"
        },
        {
          name  = "RabbitMq__Port"
          value = "5672"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.location_service.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-location-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_task_definition" "review_service" {
  family                   = "${var.project_name}-${var.environment}-review-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.service_cpu
  memory                   = var.service_memory
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "review-service"
      image     = "${data.aws_ecr_repository.repositories["deploy/reviewservice"].repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = var.service_container_port
          hostPort      = var.service_container_port
          protocol      = "tcp"
        }
      ]
      
      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        },
        {
          name  = "ASPNETCORE_HTTP_PORTS"
          value = "8080"
        },
        {
          name  = "ConnectionStrings__DefaultConnection"
          value = "Host=${aws_db_instance.postgres.address};Port=${aws_db_instance.postgres.port};Database=${aws_db_instance.postgres.db_name};Username=${aws_db_instance.postgres.username};Password=${aws_db_instance.postgres.password}"
        },
        {
          name  = "Jwt__Key"
          value = "YourSuperSecretKey12345678901234567890"
        },
        {
          name  = "Jwt__Issuer"
          value = "MicroservicesApp"
        },
        {
          name  = "Jwt__Audience"
          value = "MicroservicesClient"
        },
        {
          name  = "RabbitMq__HostName"
          value = aws_service_discovery_service.rabbitmq.name
        },
        {
          name  = "RabbitMq__UserName"
          value = "guest"
        },
        {
          name  = "RabbitMq__Password"
          value = "guest"
        },
        {
          name  = "RabbitMq__Port"
          value = "5672"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.review_service.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-review-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${var.project_name}.local"
  description = "Service discovery namespace for ${var.project_name}"
  vpc         = aws_vpc.main.id
}

# Service Discovery Services
resource "aws_service_discovery_service" "rabbitmq" {
  name = "rabbitmq"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# ECS Services
resource "aws_ecs_service" "rabbitmq" {
  name                               = "${var.project_name}-${var.environment}-rabbitmq"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.rabbitmq.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 60
  force_new_deployment               = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.rabbitmq.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.rabbitmq.arn
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rabbitmq"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_service" "user_service" {
  name                               = "${var.project_name}-${var.environment}-user-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.user_service.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 60
  force_new_deployment               = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_services.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.user_service.arn
    container_name   = "user-service"
    container_port   = var.service_container_port
  }

  depends_on = [aws_lb_listener.http, aws_iam_role_policy_attachment.ecs_execution_role_policy]

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_service" "location_service" {
  name                               = "${var.project_name}-${var.environment}-location-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.location_service.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 60
  force_new_deployment               = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_services.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.location_service.arn
    container_name   = "location-service"
    container_port   = var.service_container_port
  }

  depends_on = [aws_lb_listener.http, aws_iam_role_policy_attachment.ecs_execution_role_policy, aws_ecs_service.rabbitmq]

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-location-service"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_service" "review_service" {
  name                               = "${var.project_name}-${var.environment}-review-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.review_service.arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"
  health_check_grace_period_seconds  = 60
  force_new_deployment               = true

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_services.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.review_service.arn
    container_name   = "review-service"
    container_port   = var.service_container_port
  }

  depends_on = [aws_lb_listener.http, aws_iam_role_policy_attachment.ecs_execution_role_policy, aws_ecs_service.rabbitmq, aws_ecs_service.location_service]

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-review-service"
    Environment = var.environment
    Project     = var.project_name
  }
}