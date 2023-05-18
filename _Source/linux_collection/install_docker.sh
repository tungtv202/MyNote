echo "---remove old docker"
sudo apt-get remove docker docker-engine docker.io containerd runc
echo "--setup repository"
sudo apt-get update -y
# https://docs.docker.com/engine/install/ubuntu/

sudo usermod -aG docker $USER