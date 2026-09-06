output "url" {
  value       = aws_lb.app.dns_name
  description = "final load balancer url"
}

output "acm_validation_cnames" {
  description = "DNS records required to validate the ACM certificate"

  value = length(aws_acm_certificate.cert) == 0 ? null : [
    for option in aws_acm_certificate.cert[0].domain_validation_options : {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  ]
}