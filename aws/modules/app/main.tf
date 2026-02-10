locals {
  name      = var.project_name
  vpc_id    = var.use_existing_vpc ? var.existing_vpc_id : aws_vpc.this[0].id
  subnet_id = var.use_existing_vpc ? var.existing_subnet_id : aws_subnet.public_a[0].id
  eic_sg_id = var.eic_sg_id != "" ? var.eic_sg_id : (var.create_eic_endpoint ? aws_security_group.eic[0].id : "")
  ami_id    = var.ami_id != "" ? var.ami_id : data.aws_ami.by_name[0].id
  log_insights_enabled = var.enable_log_insights
  spring_logs_enabled  = local.log_insights_enabled && length(var.spring_log_group_names) > 0
  nginx_logs_enabled   = local.log_insights_enabled && length(var.nginx_log_group_names) > 0
  logs_any_enabled     = local.spring_logs_enabled || local.nginx_logs_enabled
  spring_sources       = join(" | ", [for lg in var.spring_log_group_names : "SOURCE '${lg}'"])
  nginx_sources        = join(" | ", [for lg in var.nginx_log_group_names : "SOURCE '${lg}'"])
}

data "aws_region" "current" {}

data "aws_ami" "by_name" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = var.ami_owners

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_iam_instance_profile" "this" {
  count = var.instance_profile_name != "" ? 1 : 0
  name  = var.instance_profile_name
}

# ----------------------
# VPC / Subnet / Routing
# ----------------------
resource "aws_vpc" "this" {
  count = var.use_existing_vpc ? 0 : 1

  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.this[0].id

  tags = {
    Name = "${local.name}-igw"
  }
}

resource "aws_subnet" "public_a" {
  count                   = var.use_existing_vpc ? 0 : 1
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-a"
  }
}

resource "aws_route_table" "public" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = {
    Name = "${local.name}-rt-public"
  }
}

resource "aws_route_table_association" "public_a" {
  count          = var.use_existing_vpc ? 0 : 1
  subnet_id      = aws_subnet.public_a[0].id
  route_table_id = aws_route_table.public[0].id
}

# -------------
# Security Group
# -------------
resource "aws_security_group" "web" {
  name        = "${local.name}-sg-web"
  description = "Allow SSH/HTTP/HTTPS"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  dynamic "ingress" {
    for_each = local.eic_sg_id != "" ? [local.eic_sg_id] : []
    content {
      description              = "SSH from EIC Endpoint SG"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      security_groups          = [ingress.value]
    }
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg-web"
  }
}

# ----------------------------
# EC2 Instance Connect Endpoint
# ----------------------------
resource "aws_security_group" "eic" {
  count       = var.create_eic_endpoint ? 1 : 0
  name        = "${local.name}-sg-eic-endpoint"
  description = "Security group for EC2 Instance Connect Endpoint"
  vpc_id      = local.vpc_id

  ingress {
    description = "EIC client access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = length(var.eic_ingress_cidr) > 0 ? var.eic_ingress_cidr : [var.ssh_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg-eic-endpoint"
  }
}

resource "aws_ec2_instance_connect_endpoint" "this" {
  count = var.create_eic_endpoint ? 1 : 0

  subnet_id          = local.subnet_id
  security_group_ids = [aws_security_group.eic[0].id]

  tags = {
    Name = "${local.name}-eic-endpoint"
  }
}
# ----
# EC2
# ----
resource "aws_instance" "app" {
  ami                         = local.ami_id
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile        = var.instance_profile_name != "" ? data.aws_iam_instance_profile.this[0].name : null

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name}-ec2"
  }
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id

  tags = {
    Name = "${local.name}-eip"
  }
}

# -----------------------------
# CloudWatch Logs Insights
# -----------------------------
resource "aws_cloudwatch_query_definition" "spring_loadtest_recent" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-spring-loadtest-recent"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields @timestamp, level, message, path, status, latency, loadtest
| filter loadtest = 'true'
| sort @timestamp desc
| limit 50
EOT
}

resource "aws_cloudwatch_query_definition" "spring_loadtest_errors" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-spring-loadtest-errors"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields @timestamp, level, message, path, status, latency, loadtest
| filter loadtest = 'true' and (level = 'ERROR' or status >= 500)
| sort @timestamp desc
| limit 50
EOT
}

resource "aws_cloudwatch_query_definition" "spring_loadtest_slow" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-spring-loadtest-slow"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields @timestamp, path, status, latency, loadtest
| filter loadtest = 'true' and latency >= 1
| sort latency desc
| limit 50
EOT
}

resource "aws_cloudwatch_query_definition" "spring_loadtest_p95_by_path" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-spring-loadtest-p95-by-path"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields path, latency, loadtest
| filter loadtest = 'true'
| stats avg(latency) as avg, pct(latency, 95) as p95, count() as cnt by path
| sort p95 desc
EOT
}

resource "aws_cloudwatch_query_definition" "spring_loadtest_status" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-spring-loadtest-status"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields status, loadtest
| filter loadtest = 'true'
| stats count() as cnt by status
| sort cnt desc
EOT
}

resource "aws_cloudwatch_query_definition" "nginx_loadtest_recent" {
  count = local.nginx_logs_enabled ? 1 : 0

  name            = "${local.name}-nginx-loadtest-recent"
  log_group_names = var.nginx_log_group_names
  query_string    = <<-EOT
fields @timestamp, uri, status, request_time, upstream_time, loadtest
| filter loadtest = 'true'
| sort @timestamp desc
| limit 50
EOT
}

resource "aws_cloudwatch_query_definition" "spring_k6_core_recent" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-k6-core-recent"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields @timestamp, path, status, latency, trace_id, loadtest, instance_id
| filter loadtest = 'true' and (
  path = '/api/dev/auth/login' or
  path = '/api/health' or
  path = '/api/user/profile' or
  startswith(path, '/api/problems') or
  startswith(path, '/api/summary-cards/submissions') or
  startswith(path, '/api/quizzes/') or
  startswith(path, '/api/problems/') or
  path = '/api/chatbot/messages/stream'
)
| sort @timestamp desc
| limit 100
EOT
}

resource "aws_cloudwatch_query_definition" "spring_k6_sse" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-k6-sse"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields @timestamp, status, latency, trace_id, loadtest, instance_id
| filter loadtest = 'true' and path = '/api/chatbot/messages/stream'
| sort @timestamp desc
| limit 100
EOT
}

resource "aws_cloudwatch_query_definition" "spring_k6_by_instance" {
  count = local.spring_logs_enabled ? 1 : 0

  name            = "${local.name}-k6-by-instance"
  log_group_names = var.spring_log_group_names
  query_string    = <<-EOT
fields instance_id, path, latency, loadtest
| filter loadtest = 'true'
| stats count() as cnt, pct(latency, 95) as p95 by instance_id, path
| sort p95 desc
| limit 50
EOT
}

locals {
  spring_widget_height = local.spring_logs_enabled ? 30 : 0
  nginx_widget_height  = local.nginx_logs_enabled ? 6 : 0
  k6_section_base_y    = local.spring_widget_height + local.nginx_widget_height
  spring_widgets = local.spring_logs_enabled ? [
    {
      type  = "log"
      x     = 0
      y     = 0
      width = 24
      height = 6
      properties = {
        title  = "Spring Loadtest Recent"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields @timestamp, level, message, path, status, latency, loadtest | filter loadtest = 'true' | sort @timestamp desc | limit 50"
      }
    },
    {
      type  = "log"
      x     = 0
      y     = 6
      width = 24
      height = 6
      properties = {
        title  = "Spring Loadtest Errors"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields @timestamp, level, message, path, status, latency, loadtest | filter loadtest = 'true' and (level = 'ERROR' or status >= 500) | sort @timestamp desc | limit 50"
      }
    },
    {
      type  = "log"
      x     = 0
      y     = 12
      width = 24
      height = 6
      properties = {
        title  = "Spring Loadtest Slow (>=1s)"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields @timestamp, path, status, latency, loadtest | filter loadtest = 'true' and latency >= 1 | sort latency desc | limit 50"
      }
    },
    {
      type  = "log"
      x     = 0
      y     = 18
      width = 24
      height = 6
      properties = {
        title  = "Spring Loadtest P95 by Path"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields path, latency, loadtest | filter loadtest = 'true' | stats avg(latency) as avg, pct(latency, 95) as p95, count() as cnt by path | sort p95 desc"
      }
    },
    {
      type  = "log"
      x     = 0
      y     = 24
      width = 24
      height = 6
      properties = {
        title  = "Spring Loadtest Status Codes"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields status, loadtest | filter loadtest = 'true' | stats count() as cnt by status | sort cnt desc"
      }
    }
  ] : []
  nginx_widgets = local.nginx_logs_enabled ? [
    {
      type  = "log"
      x     = 0
      y     = local.spring_widget_height
      width = 24
      height = 6
      properties = {
        title  = "Nginx Loadtest Recent"
        region = data.aws_region.current.name
        query  = "${local.nginx_sources} | fields @timestamp, uri, status, request_time, upstream_time, loadtest | filter loadtest = 'true' | sort @timestamp desc | limit 50"
      }
    }
  ] : []
  k6_widgets = local.spring_logs_enabled ? [
    {
      type  = "text"
      x     = 0
      y     = local.k6_section_base_y
      width = 24
      height = 2
      properties = {
        markdown = "## K6 Loadtest 그룹"
      }
    },
    {
      type  = "log"
      x     = 0
      y     = local.k6_section_base_y + 2
      width = 24
      height = 6
      properties = {
        title  = "K6 Core Recent"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields @timestamp, path, status, latency, trace_id, loadtest, instance_id | filter loadtest = 'true' and (path = '/api/dev/auth/login' or path = '/api/health' or path = '/api/user/profile' or startswith(path, '/api/problems') or startswith(path, '/api/summary-cards/submissions') or startswith(path, '/api/quizzes/') or startswith(path, '/api/problems/') or path = '/api/chatbot/messages/stream') | sort @timestamp desc | limit 100"
      }
    },
    {
      type  = "log"
      x     = 0
      y     = local.k6_section_base_y + 8
      width = 24
      height = 6
      properties = {
        title  = "K6 SSE"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields @timestamp, status, latency, trace_id, loadtest, instance_id | filter loadtest = 'true' and path = '/api/chatbot/messages/stream' | sort @timestamp desc | limit 100"
      }
    },
    {
      type  = "log"
      x     = 0
      y     = local.k6_section_base_y + 14
      width = 24
      height = 6
      properties = {
        title  = "K6 By Instance"
        region = data.aws_region.current.name
        query  = "${local.spring_sources} | fields instance_id, path, latency, loadtest | filter loadtest = 'true' | stats count() as cnt, pct(latency, 95) as p95 by instance_id, path | sort p95 desc | limit 50"
      }
    }
  ] : []
  log_widgets = concat(local.spring_widgets, local.nginx_widgets, local.k6_widgets)
}

resource "aws_cloudwatch_dashboard" "log_insights" {
  count = local.logs_any_enabled ? 1 : 0

  dashboard_name = "${local.name}-log-insights"
  dashboard_body = jsonencode({
    widgets = local.log_widgets
  })
}
