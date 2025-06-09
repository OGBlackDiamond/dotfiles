
cd ~/; mkdir dev

echo Starting fresh installation process...
echo \nThis installation script was designed for RHEL based systems that run KDE by default

echo \n\nEnabling third party repositories...

dnf copr enable solopasha/hyprland
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm


echo \n\nInstalling nessecary packages

sudo dnf install nvim btop cava code gh git

curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java


echo \n\nInstalling Hyperland
sudo dnf install hyprland dunst xdg-desktop-portal-hyprland hyprpolkitagent qt6-wayland waybar hyprpaper rofi

echo \n\nChanging default DE to Hyperland

sed -i '3s/.*/Session=hyprland/' /etc/ssdm.conf.d/kde_settings.conf


echo \n\nSetting up github authentication
ssh-keygen -t rsa

gh auth login

gh ssh-key add .ssh/id_rsa.pub --type signing
gh ssh-key add .ssh/id_rsa.pub --type authentication


echo \n\nPulling FFUS and applying...
cd dev; git clone git@github.com:OGBlackDiamond/firefox-user-styles.git; python3 configure.py
