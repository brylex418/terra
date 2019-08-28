    #!/bin/bash
    sudo apt udpate -y
    sudo apt install apache2 -y
    echo "<h1>"Deployed Via Terraform"</h1>" | sudo tee /var/www/html/index.html
    sudo systemctl start apache2
    sudo systemctl enable apache2