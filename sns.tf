# alarm sns topics
locals {
  # build a map of topics from the list input
  alarm_sns_topics = {
    for o in var.alarm_sns_topics : o.name => o
  }
}

# iam resources for alarm lambda functions
locals {
  alarm_log_group_arn_prefix = format(
    "arn:aws:logs:*:%s:log-group:/aws/lambda/alarm-",
    data.aws_caller_identity.current.account_id,
  )
}

data "aws_iam_policy_document" "alarm_lambda_assume_role" {
  count = length(local.alarm_sns_topics) > 0 ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "alarm_lambda_execution_role" {
  for_each = local.alarm_sns_topics

  name               = "alarm-${each.key}-lambda-function"
  description        = "Execution role for CloudWatch Alarm ${each.key} lambda function"
  assume_role_policy = data.aws_iam_policy_document.alarm_lambda_assume_role[0].json
  tags               = var.tags
}

data "aws_iam_policy_document" "alarm_lambda_access" {
  for_each = local.alarm_sns_topics

  statement {
    actions = compact([
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ])
    resources = [
      "${local.alarm_log_group_arn_prefix}${each.key}:*",
      "${local.alarm_log_group_arn_prefix}${each.key}:*:*",
    ]
  }
}

resource "aws_iam_policy" "alarm_lambda_access" {
  for_each = local.alarm_sns_topics

  name   = "alarm-${each.key}-lambda-function"
  policy = data.aws_iam_policy_document.alarm_lambda_access[each.key].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "alarm_lambda_access" {
  for_each = local.alarm_sns_topics

  role       = aws_iam_role.alarm_lambda_execution_role[each.key].name
  policy_arn = aws_iam_policy.alarm_lambda_access[each.key].arn
}

# create the lambda function
locals {
  # default settings for different supported publish types
  alarm_lambda_settings_defaults = {
    slack = {
      source_code_path    = "${path.module}/assets/default-slack-notifier-lambda-function/index.js"
      zip_source_filename = "index.js"
      handler             = "index.handler"
      runtime             = "nodejs20.x"
    }
    teams = {
      source_code_path    = "${path.module}/assets/default-teams-notifier-lambda-function/index.js"
      zip_source_filename = "index.js"
      handler             = "index.handler"
      runtime             = "nodejs20.x"
    }
  }

  alarm_lambda_settings = merge(
    local.alarm_lambda_settings_defaults,
    var.alarm_lambda_settings,
  )
}

# create the zip file for the alarm lambda function
data "archive_file" "alarm_lambda_code" {
  for_each = local.alarm_sns_topics

  type             = "zip"
  output_file_mode = "0666"

  source {
    content  = file(local.alarm_lambda_settings[each.value.publish_target_type].source_code_path)
    filename = local.alarm_lambda_settings[each.value.publish_target_type].zip_source_filename
  }

  # set a unique filename based on the hash of the source code file so that the
  # canary resource will identify a change if the file name changes to update
  # the function code.
  output_path = format(
    "%s/generated-archives/lambda-function-%s-%s.zip",
    path.module, each.key, filemd5(local.alarm_lambda_settings[each.value.publish_target_type].source_code_path),
  )
}

resource "aws_lambda_function" "alarm" {
  for_each = local.alarm_sns_topics

  function_name = "alarm-${each.key}"
  role          = aws_iam_role.alarm_lambda_execution_role[each.key].arn
  handler       = local.alarm_lambda_settings[each.value.publish_target_type].handler
  runtime       = local.alarm_lambda_settings[each.value.publish_target_type].runtime
  filename      = data.archive_file.alarm_lambda_code[each.key].output_path

  environment {
    variables = {
      WEBHOOK_URL = each.value.webhook_url
    }
  }
}

# create sns topic
resource "aws_sns_topic" "alarms" {
  for_each = local.alarm_sns_topics

  name = each.key
}

# create the sns topic subscription to the lambda function
resource "aws_sns_topic_subscription" "alarm_lambda" {
  for_each = local.alarm_sns_topics

  topic_arn = aws_sns_topic.alarms[each.key].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm[each.key].arn
}

# permission for sns to execute lambda
resource "aws_lambda_permission" "alarm_sns_access" {
  for_each = local.alarm_sns_topics

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm[each.key].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarms[each.key].arn
}
