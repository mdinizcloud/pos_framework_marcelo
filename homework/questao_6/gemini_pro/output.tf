# outputs.tf

output "bucket_id" {
  description = "O nome final do bucket S3 gerado"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "O ARN (Amazon Resource Name) do bucket S3"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "O nome de domínio (FQDN) do bucket S3"
  value       = aws_s3_bucket.this.bucket_domain_name
}