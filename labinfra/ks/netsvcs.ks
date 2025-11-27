# Full noninteractive. Die if any unanswered questions
cmdline

# Prevent firstboot from spawning on first boot
firstboot --disable


# The following is considered a well-known password
rootpw --plaintext VMl4bP@$5

ignoredisk --only-use=vda
clearpart --initlabel --drives=vda
zerombr
autopart --fstype=ext4 --nohome --noswap --type=plain


# We don't need to specify the BaseOS/AppStream repo location, as it is specified on the kernel command line
repo --name=vmlab --baseurl=http://10.123.21.1/labrpms

skipx

# Minimal base install
%packages --nocore
@base --nodefaults

# Use the lab-specific repos rpm
-rocky-repos
vmlab-repos

# Needed to keep kpatch happy
dnf-plugins-core

# Human comforts
less
vim
zsh
mc

# Gotta have it
openssh-server

%end

# I'm opinionated!
%post
chsh -s /usr/bin/zsh

cat <<-END > /usr/local/bin/rebuild-mgmt
#!/usr/bin/env sh
wipefs -af /dev/vda
reboot
END
chmod +x /usr/local/bin/rebuild-mgmt

%end


# When done, reboot into the installed OS
reboot
