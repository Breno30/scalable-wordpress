output "url" {
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_lb.app.dns_name}"
  description = "URL to open after deployment"
}

output "certificate_validation_cname" {
  description = "Create this CNAME at your DNS provider, then run terraform apply again"

  value = length(aws_acm_certificate.cert) == 0 ? null : {
    type      = one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_type
    name      = one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_name
    points_to = one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_value
  }
}
