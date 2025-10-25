dnf --quiet list --showduplicates conmon crun netavark passt \*catatonit aardvark-dns
dnf --quiet list --showduplicates golang rust podman
release="$(rpm -q --qf "%{NAME}" -qf /etc/os-release)"
dnf --quiet list --showduplicates --available $release
