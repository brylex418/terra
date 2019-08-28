output "wp_dev_public_ip" {
    value = "${aws_instance.wp_dev.public_ip}"
}

output "NLB_public_addr" {
    value = "${aws_lb.wp_lb.dns_name}"
}