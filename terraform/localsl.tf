locals {
  primary_user_data = <<-EOF
    #!/bin/bash

    set -e

    # Update system
    dnf update -y

    # Install Apache, PHP and required extensions
    dnf install -y \
      httpd \
      php \
      php-mysqlnd \
      php-fpm \
      php-json \
      php-gd \
      php-mbstring \
      php-xml \
      php-curl \
      php-zip \
      amazon-efs-utils

    # Enable and start Apache
    systemctl enable httpd
    systemctl start httpd

    # Create WordPress directory
    mkdir -p /var/www/html

    # Mount EFS
    # mount -t efs ${aws_efs_file_system.website.dns_name}:/ /var/www/html
    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.website.dns_name}:/ /var/www/html



    # Download WordPress
    cd /tmp
    curl -O https://wordpress.org/latest.tar.gz

    # Extract WordPress
    tar -xzf latest.tar.gz

    # Copy WordPress files
    cp -r wordpress/* /var/www/html/

    # Set permissions
    chown -R apache:apache /var/www/html
    chmod -R 755 /var/www/html

    # Create WordPress configuration
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

    # Configure database
    sed -i "s/database_name_here/${var.db_name}/" /var/www/html/wp-config.php
    sed -i "s/username_here/${var.db_username}/" /var/www/html/wp-config.php
    sed -i "s/password_here/${var.db_password}/" /var/www/html/wp-config.php
    sed -i "s/localhost/${aws_db_instance.mysql.address}/" /var/www/html/wp-config.php

    # Restart Apache
    systemctl restart httpd

    # Enable and start SSM Agent
    dnf install -y amazon-ssm-agent
    systemctl enable --now amazon-ssm-agent
  EOF
}