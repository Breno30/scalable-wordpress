output "url" {
  value       = aws_lb.app.dns_name
  description = "final load balancer url"
}
