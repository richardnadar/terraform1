# Using aws cloud
provider  "aws" {
  region     = "us-east-1"
  shared_credentials_file = "/../../../ilann/.aws/credentials"
}

# Entering private key for authentication
variable  "enter_key_name" {
	type = string
//	default = "mykey1111"
}

# creation of bucket
resource "aws_s3_bucket" "my-buck" {
  bucket = "richbucket674"
  acl = "public-read"
  versioning {
    enabled = true
  }


  tags = {
    Name = "my-bucket-1"
  }
}


# Creating a cloudfront
resource "aws_cloudfront_distribution" "img-cloud-front" {
    origin {
        domain_name = "richbucket674.s3.amazonaws.com"
        origin_id = "S3-richbucket674" 


        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
       
    enabled = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-richbucket674"


        # Forward all query strings, cookies and headers
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
    # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }


    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

# Creating security group or firewall
resource  "aws_security_group" "my_firewall_1" {
  name          = "allow-tls-t"
  description = "Allow TLS inbound traffic"
  vpc_id        = "vpc-58b8a722"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "protect-1"
  }
}


# Provisioning instance
resource "aws_instance" "my-sys-1" {
  ami           = "ami-09d95fab7fff3776c"
  instance_type = "t2.micro"
  key_name = "mykey1111"
  vpc_security_group_ids = ["${aws_security_group.my_firewall_1.id}"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/ilann/Downloads/mykey1111.pem")
    host     = aws_instance.my-sys-1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "myos1"
  }

}

# Creating EBS volume
resource "aws_ebs_volume" "my-ebs-1" {
  availability_zone = aws_instance.my-sys-1.availability_zone
  size              = 1
  tags = {
    Name = "myebsvol"
  }
}


# Attaching volume to the instance
resource "aws_volume_attachment" "ebs_attach_1" {
  device_name = "/dev/sdg"
  volume_id   = "${aws_ebs_volume.my-ebs-1.id}"
  instance_id = "${aws_instance.my-sys-1.id}"
  force_detach = true
  depends_on = [
    aws_ebs_volume.my-ebs-1,
    aws_instance.my-sys-1
  ]
}

output "my_sys_ip" {
  value = aws_instance.my-sys-1.public_ip
}



# Partition, format and mounting of the volume
#copying contents of github to our web server
resource "null_resource" "null-remote-con"  {

  depends_on = [
    aws_volume_attachment.ebs_attach_1,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/ilann/Downloads/mykey1111.pem")
    host     = aws_instance.my-sys-1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdg",
      "sudo mount  /dev/xvdg  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/ther1chie/terraform1.git /var/www/html/"
    ]
  }
}


