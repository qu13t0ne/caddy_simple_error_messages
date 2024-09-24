#!/bin/bash

# [[ INSTALL CADDY XCADDY CLOUDFLARE-DNS ]]

# [ install golang (required by xcaddy) ]
echo ""
echo ""
echo "ACTION REQUIRED: Download and install Go (Golang)"
echo "- Visit https://go.dev/dl/"
echo "- Identify and copy the direct download URL for the latest stable release of Go"
echo "  for Linux. It will be something like 'go<version>.linux-amd64.tar.gz'"
echo "- Paste the URL in the prompt below"
read -r -p "Download URL: " url
read -r -p "SHA256 Checksum: " checksum
wget "$url"
go_tar=$(basename "$url")
if output=$(echo "$checksum  $go_tar" | sha256sum --check); then
    echo "$output"
else
    echo "$output"
    echo "Do you want to continue even though checksum did not match?"
    echo "Any response other than 'Y' will terminate script."
    read -r -p "To continue, enter 'Y', otherwise any key to terminate: " response
    case "$response" in
    Y | y)
        echo "Continuing..."
        ;;
    *)
        echo "Terminating script. Go and Caddy are NOT installed."
        exit 1
        ;;
    esac
fi

#remove previous Go installations
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "$go_tar"
#add to path
sudo bash -c 'echo -e "# Add Go (Golang) to system PATH\nexport PATH=\$PATH:/usr/local/go/bin" >> /etc/profile'
export PATH=$PATH:/usr/local/go/bin
#validate
if output=$(go version); then
    echo "$output"
else
    echo "$output"
    echo "Unable to validate Go install. Continue anyway, or exit and manually validate Go is added to path before continuing?"
    echo "Any response other than 'Y' will terminate script."
    read -r -p "To continue, enter 'Y', otherwise any key to terminate: " response
    case "$response" in
    Y | y)
        echo "Continuing..."
        ;;
    *)
        echo "Terminating script."
        echo "Try adding the following to your bashrc/zshrc/shell profile and re-sourcing the profile. Then run 'go version' to confirm go is installed and usable."
        exit 1
        ;;
    esac
fi

# remove tar file
rm "$go_tar"

# [ install caddy ]
# - ref: https://caddyserver.com/docs/install#debian-ubuntu-raspbian

sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

# [ install xcaddy ]
# - ref: https://github.com/caddyserver/xcaddy
# - ref: https://caddyserver.com/docs/build#xcaddy

sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-xcaddy-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/xcaddy/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-xcaddy.list
sudo apt update
sudo apt install xcaddy

# [ build custom CLOUDFLARE-DNS caddy binary with xcaddy ]
# - ref: https://caddyserver.com/docs/modules/dns.providers.cloudflare

xcaddy build \
    --with github.com/caddy-dns/cloudflare

# Package support files for custom builds for Debian/Ubuntu/Raspbian
# - ref: https://caddyserver.com/docs/build#package-support-files-for-custom-builds-for-debianubunturaspbian

sudo dpkg-divert --divert /usr/bin/caddy.default --rename /usr/bin/caddy
sudo mv ./caddy /usr/bin/caddy.custom
sudo update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.default 10
sudo update-alternatives --install /usr/bin/caddy caddy /usr/bin/caddy.custom 50
sudo systemctl restart caddy
