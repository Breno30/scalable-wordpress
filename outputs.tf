output "url" {
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_lb.app.dns_name}"
  description = "URL to open after deployment"
}

output "load_balancer_dns_name" {
  value       = aws_lb.app.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "certificate_validation_cname" {
  description = "Create this CNAME at your DNS provider, then run terraform apply again"

  value = length(aws_acm_certificate.cert) == 0 ? null : {
    type      = one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_type
    name      = one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_name
    points_to = one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_value
  }
}

output "certificate_validation_tutorial" {
  description = "Human-readable instructions for validating the ACM certificate"

  value = length(aws_acm_certificate.cert) == 0 ? null : <<-EOT
    ADD THIS CNAME TO YOUR DNS

    1. Sign in to the DNS provider for ${var.domain_name}.
    2. Open the DNS records page and add a new record with these values:

       Type:   ${one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_type}
       Name:   ${one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_name}
       Target: ${one(aws_acm_certificate.cert[0].domain_validation_options).resource_record_value}

    3. Save the record. Keep the Name and Target exactly as shown.
    4. Wait for the DNS change to propagate.
    5. Run `terraform apply` to validate the certificate and deploy the stack.
  EOT
}

output "domain_routing_tutorial" {
  description = "Human-readable instructions for routing the custom domain to the load balancer"

  value = var.domain_name == "" ? null : <<-EOT
    POINT YOUR SUBDOMAIN TO THE LOAD BALANCER

    The ACM validation CNAME only verifies domain ownership. Create this second
    DNS record so visitors to ${var.domain_name} reach the application:

       Type:   CNAME
       Name:   ${var.domain_name}
       Target: ${aws_lb.app.dns_name}

    Some DNS providers expect only the host label in Name (for example,
    "wordpress" instead of "wordpress.example.com").

    Keep the ACM validation CNAME in place for automatic certificate renewal.
    After this record propagates, open https://${var.domain_name}.
  EOT
}
