locals {
  synthetics_canary_defaults = {
    artifact_s3_location_prefix = "s3://${local.synthetics_bucket_name}/"
    handler                     = "index.handler"
    runtime_version             = "syn-nodejs-puppeteer-3.6"
    source_code_path            = "${path.module}/assets/default-synthetics-lambda-function/index.js"
    delete_lambda               = true
    schedule_expression         = "rate(5 minutes)"
    timeout_in_seconds          = 60
    environment_variables       = {}
    create_alarm                = true
    alarm_config = {
      # default alarm will alert on multiple failures over 15 minutes
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 1
      period              = 900
      statistic           = "Average"
      threshold           = "66"
      alarm_description   = "Alert when canary success percentage has decreased below 66% in the last 15 minutes"
    }
  }

  # Default canary configuration for each field if the value is null
  # Terraform 1.3 will likely have a feature to do this automatically in the
  # variable declaration which will simplify what's required here and improve
  # user implementation
  synthetics_canaries = {
    for o in var.cloudwatch_synthetics_canaries : o.name => {
      artifact_s3_location  = o.artifact_s3_location == null ? "${local.synthetics_canary_defaults.artifact_s3_location_prefix}${o.name}/" : o.artifact_s3_location
      handler               = o.handler == null ? local.synthetics_canary_defaults.handler : o.handler
      runtime_version       = o.runtime_version == null ? local.synthetics_canary_defaults.runtime_version : o.runtime_version
      source_code_path      = o.source_code_path == null ? local.synthetics_canary_defaults.source_code_path : o.source_code_path
      delete_lambda         = o.delete_lambda == null ? local.synthetics_canary_defaults.delete_lambda : o.delete_lambda
      schedule_expression   = o.schedule_expression == null ? local.synthetics_canary_defaults.schedule_expression : o.schedule_expression
      timeout_in_seconds    = o.timeout_in_seconds == null ? local.synthetics_canary_defaults.timeout_in_seconds : o.timeout_in_seconds
      environment_variables = o.environment_variables == null ? local.synthetics_canary_defaults.environment_variables : o.environment_variables
      create_alarm          = o.create_alarm == null ? local.synthetics_canary_defaults.create_alarm : o.create_alarm
      alarm_config          = o.alarm_config == null ? local.synthetics_canary_defaults.alarm_config : o.alarm_config
    }
  }
}

# synthetics s3 dependencies
locals {
  create_synthetics_bucket = var.create_cloudwatch_synthetics_bucket

  default_synthetics_bucket_name = "${data.aws_caller_identity.current.account_id}-cloudwatch-synthetics-artifacts"
  synthetics_bucket_name = coalesce(
    var.cloudwatch_synthetics_bucket_name_override,
    local.default_synthetics_bucket_name,
  )
}

resource "aws_s3_bucket" "cloudwatch_synthetics_artifacts" {
  count  = local.create_synthetics_bucket ? 1 : 0
  bucket = local.synthetics_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_acl" "cloudwatch_synthetics_artifacts" {
  count  = local.create_synthetics_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudwatch_synthetics_artifacts[count.index].id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudwatch_synthetics_artifacts" {
  count  = local.create_synthetics_bucket ? 1 : 0
  bucket = aws_s3_bucket.cloudwatch_synthetics_artifacts[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# synthetics iam dependencies for canary lambda function
locals {
  synthetics_log_group_arn_prefix = format(
    "arn:aws:logs:%s:%s:log-group:/aws/lambda/cwsyn-",
    data.aws_region.current.name,
    data.aws_caller_identity.current.account_id,
  )
}

data "aws_iam_policy_document" "cloudwatch_synthetics_assume_role" {
  count = length(var.cloudwatch_synthetics_canaries) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_synthetics_execution_role" {
  for_each = local.synthetics_canaries

  name               = "cloudwatch-synthetics-${each.key}-lambda-function"
  description        = "Execution role for CloudWatch Synthetic Canary ${each.key} lambda function"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_synthetics_assume_role[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "cloudwatch_synthetics_access" {
  for_each = local.synthetics_canaries

  statement {
    actions = compact([
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ])
    resources = [
      "${local.synthetics_log_group_arn_prefix}${each.key}:*",
      "${local.synthetics_log_group_arn_prefix}${each.key}:*:*",
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = ["arn:aws:s3:::${local.synthetics_bucket_name}/*"]
  }

  statement {
    actions   = ["s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${local.synthetics_bucket_name}"]
  }

  statement {
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
  }
}

resource "aws_iam_policy" "cloudwatch_synthetics_access" {
  for_each = local.synthetics_canaries

  name   = "cloudwatch-synthetics-${each.key}-lambda-function"
  policy = data.aws_iam_policy_document.cloudwatch_synthetics_access[each.key].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_synthetics_access" {
  for_each = local.synthetics_canaries

  role       = aws_iam_role.cloudwatch_synthetics_execution_role[each.key].name
  policy_arn = aws_iam_policy.cloudwatch_synthetics_access[each.key].arn
}

# create the zip file for the canary lambda function
data "archive_file" "synthetic_canary_lambda_code" {
  for_each = local.synthetics_canaries

  type             = "zip"
  output_file_mode = "0666"

  source {
    content  = file(each.value.source_code_path)
    filename = "nodejs/node_modules/index.js"
  }

  # set a unique filename based on the hash of the source code file so that the
  # canary resource will identify a change if the file name changes to update
  # the function code.
  output_path = format(
    "%s/generated-archives/lambda-function-%s-%s.zip",
    path.module, each.key, filemd5(each.value.source_code_path),
  )
}

resource "aws_synthetics_canary" "canary" {
  for_each = local.synthetics_canaries

  name                 = each.key
  artifact_s3_location = each.value.artifact_s3_location
  handler              = each.value.handler
  runtime_version      = each.value.runtime_version
  delete_lambda        = each.value.delete_lambda
  zip_file             = data.archive_file.synthetic_canary_lambda_code[each.key].output_path
  execution_role_arn   = aws_iam_role.cloudwatch_synthetics_execution_role[each.key].arn
  start_canary         = true

  schedule {
    expression = each.value.schedule_expression
  }

  run_config {
    timeout_in_seconds    = each.value.timeout_in_seconds
    environment_variables = each.value.environment_variables
  }

  tags = var.tags
}

# cloudwatch alarm
resource "aws_cloudwatch_metric_alarm" "canary_alarm" {
  for_each = {
    # rebuild synthetics_canaries map, only include canaries that have an alarm enabled
    for k, v in local.synthetics_canaries : k => v
    if v.create_alarm
  }

  alarm_name         = "${each.key}-canary"
  metric_name        = "SuccessPercent"
  namespace          = "CloudWatchSynthetics"
  treat_missing_data = "breaching"

  comparison_operator = each.value.alarm_config.comparison_operator
  evaluation_periods  = each.value.alarm_config.evaluation_periods
  period              = each.value.alarm_config.period
  statistic           = each.value.alarm_config.statistic
  threshold           = each.value.alarm_config.threshold
  alarm_description   = each.value.alarm_config.alarm_description

  # publish to all "alarm" sns topics that we created
  alarm_actions             = [for _, v in aws_sns_topic.alarms : v.arn]
  insufficient_data_actions = [for _, v in aws_sns_topic.alarms : v.arn]
  ok_actions                = [for _, v in aws_sns_topic.alarms : v.arn]

  dimensions = {
    "CanaryName" = each.key
  }
}
