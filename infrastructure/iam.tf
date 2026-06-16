###########################
# OIDC FOR CIRCLECI
###########################

resource "aws_iam_openid_connect_provider" "circleci" {
  url = "https://oidc.circleci.com/org/3d486836-f76c-47b4-9540-72a40f609aa1"

  client_id_list = [
    "3d486836-f76c-47b4-9540-72a40f609aa1"
  ]

  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da0ecd4e0f9"
  ]

  tags = local.common_tags
}

###########################
# CIRCLECI DEPLOY ROLE
###########################

resource "aws_iam_role" "circleci_deploy" {
  name = "circleci-cinema-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.circleci.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "oidc.circleci.com/org/3d486836-f76c-47b4-9540-72a40f609aa1:aud" = "3d486836-f76c-47b4-9540-72a40f609aa1"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

###########################
# DEPLOY POLICY
###########################

resource "aws_iam_role_policy" "circleci_deploy_policy" {
  name = "circleci-cinema-policy"

  role = aws_iam_role.circleci_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:*",
          "cloudfront:CreateInvalidation"
        ]

        Resource = "*"
      }
    ]
  })
}