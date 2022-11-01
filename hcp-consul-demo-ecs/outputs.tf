output "client_lb_address" {
  value = "http://${aws_lb.example_client_app.dns_name}:9090/ui"
}

output "hashicups_lb_address" {
  value = "http://${aws_lb.hashicups_frontend.dns_name}:80"
}