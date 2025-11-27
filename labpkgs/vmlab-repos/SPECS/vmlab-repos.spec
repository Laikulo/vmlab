Name:           vmlab-repos
Version:        10.0
Release:        2%{?dist}
Summary:        Repository definitions for the lab VM

BuildArch: 	noarch

License:        TBD
URL:            foobar.invalid
Source:         vmlab.repo

Requires: rocky-gpg-keys
Provides: system-repos
Provides: rocky-repos(10)

%description


%prep
cp "$RPM_SOURCE_DIR"/vmlab.repo .

%build


%install
mkdir -p %{buildroot}/etc/yum.repos.d
install vmlab.repo %{buildroot}/etc/yum.repos.d/vmlab.repo


%files
/etc/yum.repos.d/vmlab.repo


%changelog
* Wed Nov 26 2025 Super User
- 
