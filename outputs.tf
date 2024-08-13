output "app_role_arn" {
  description = "ARN of the IAM role to be assumed by the DataRobot app service accounts"
  value       = module.app_irsa_role.iam_role_arn
}
