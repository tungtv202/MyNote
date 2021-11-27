# Install git
sudo apt install git -y

# Install curl
sudo snap install curl

# Install combo ZSH
## Zsh 
sudo apt-get install zsh -y
which zsh
chsh -s $(which zsh)

## Ohmyzsh
sudo curl -L http://install.ohmyz.sh | sh
# zsh

## zsh-autosuggestions
git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
plugins=(zsh-autosuggestions)
echo "source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc

# Install terminator
sudo apt-get install -y terminator

# Install monitor
## 1. Indicator-system monitor
sudo add-apt-repository ppa:fossfreedom/indicator-sysmonitor
sudo apt-get update
sudo apt-get install indicator-sysmonitor

## 2. Psensor
sudo apt-get install lm-sensors
sudo sensors-detect
sensors
sudo apt-get install psensor


# Install autojump
## Moreinfor: https://github.com/wting/autojump

# Install bluetooth manager
sudo apt install bluez bluez-tools
sudo apt install blueman

## Imwheels
sudo apt-get install imwheel

# Install Go Tieng Viet
# https://github.com/BambooEngine/ibus-bamboo
sudo add-apt-repository ppa:bamboo-engine/ibus-bamboo
sudo apt-get update
sudo apt-get install ibus ibus-bamboo --install-recommends
ibus restart
env DCONF_PROFILE=ibus dconf write /desktop/ibus/general/preload-engines "['BambooUs', 'Bamboo']" && gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Bamboo')]"





