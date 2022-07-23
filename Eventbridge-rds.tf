########### variable
variable "oracle_alarms" {
    type =string
    default = "\"EventID\": [\"RDS-EVENT-0006\",\"RDS-EVENT-0004\",\"RDS-EVENT-0221\",\"RDS-EVENT-0222\",\"RDS-EVENT-0013\",\"RDS-EVENT-0015\",\"RDS-EVENT-0034\",\"RDS-EVENT-0049\",\"RDS-EVENT-0065\",\"RDS-EVENT-0031\",\"RDS-EVENT-0035\",\"RDS-EVENT-0036\",\"RDS-EVENT-0058\",\"RDS-EVENT-0079\",\"RDS-EVENT-0080\",\"RDS-EVENT-0165\",\"RDS-EVENT-0223\",\"RDS-EVENT-0224\",\"RDS-EVENT-0007\",\"RDS-EVENT-0089\",\"RDS-EVENT-0195\",\"RDS-EVENT-0055\",\"RDS-EVENT-0056\",\"RDS-EVENT-0087\",\"RDS-EVENT-0158\",\"RDS-EVENT-0045\",\"RDS-EVENT-0057\",\"RDS-EVENT-0202\",\"RDS-EVENT-0052\"]"
}
/*
 https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.Messages.html#USER_Events.Messages.instance> 
 */


########### SNS Topic
resource "aws_sns_topic" "topic" {
  name = "topic-name"
}


resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [aws_sns_topic.topic.arn]
  }
}

########### SNS email subscription
resource "aws_sns_topic_subscription" "email-target" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = "sylvain.vergnes@kyndryl.com"
}


########### Eventbridge rule
resource "aws_cloudwatch_event_rule" "eventbridge" {
  name        = "rds_events"
  description = "Capture RDS Events "

  event_pattern = <<EOF
{
  "source": ["aws.rds"],
  "detail-type": ["RDS DB Instance Event"],
  "detail": {
    ${var.oracle_alarms}
  }
}
EOF
}

########### Attach Eventbridge rule to the topic
resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.eventbridge.name
  target_id = "SendToEmail"
  arn       = aws_sns_topic.topic.arn
}

