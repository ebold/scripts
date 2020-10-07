# Invoke Linux commands from a web page (Arch Linux ARM)


## Install and run Apache

```
$ su
# pacman -S apache
# systemctl enable httpd.service
# systemctl start httpd.service
# systemctl -l status httpd.service
```

## Configure Apache

1. Set the server name

```
# vi /etc/httpd/conf/httpd.conf      # replace '#ServerName www.example.com:80' with 'ServerName localhost'
# systemctl restart httpd.service
```

Verify if web server ishandles HTTP request from other device by using web browser, eg, http://beaglebone

2. Enable CGI module

```
# vi /etc/httpd/conf/httpd.conf      # uncomment 'LoadModule cgid_module modules/mod_cgid.so'
# systemctl restart httpd.service
```

3. Identify the CGI scripts location

```
# grep ScriptAlias /etc/httpd/conf/httpd.conf
# ScriptAlias /cgi-bin/ "/srv/http/cgi-bin/"   # scripts are located in /srv/http/cgi-bin/
```

4. Install CGI scripts

```
# mkdir -p /srv/http/cgi-bin
# chmod +x reboot.cgi
# cp reboot.cgi /srv/http/cgi-bin/
```

## Allow to invoke Linux commands from a web page

1. Get the name of the apache user

```
# ps aux | grep httpd                # on ArchLinux apache runs as user http
http       213  0.0  0.9  12968  4668 ?        S    23:48   0:00 /usr/bin/httpd -k start -DFOREGROUND
```

2. Set a permission to Apache user

```
# pacman -S sudo                     # install sudo
# visudo /etc/sudoers                # add 'http ALL = NOPASSWD: sudo /usr/bin/systemctl reboot' at the end
```

## Resources

- Install Apache [link](https://wiki.archlinux.de/title/Apache)
- Execute linux commands from web page [link](https://www.cyberciti.biz/tips/executing-linuxunix-commands-from-web-page-part-i.html)
- Allow users to shutdown [link](https://wiki.archlinux.org/index.php/allow_users_to_shutdown)
