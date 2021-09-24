#!/bin/bash

# Credit: https://www.2daygeek.com/bash-shell-script-view-linux-system-information/

host_info() {
  echo -e "-------------------------------System Information----------------------------"
  echo -e "Hostname:\t\t"$(hostname)
  echo -e "Manufacturer:\t\t"$(cat /sys/class/dmi/id/chassis_vendor)
  echo -e "Product Name:\t\t"$(cat /sys/class/dmi/id/product_name)
  echo -e "Version:\t\t"$(cat /sys/class/dmi/id/product_version)
  echo -e "Serial Number:\t\t"$(cat /sys/class/dmi/id/product_serial)
  echo -e "Machine Type:\t\t"$(vserver=$(lscpu | grep Hypervisor | wc -l); if [ $vserver -gt 0 ]; then echo "VM"; else echo "Physical"; fi)
  echo -e "Operating System:\t"$(hostnamectl | grep "Operating System" | cut -d ' ' -f5-)
  echo -e "Kernel:\t\t\t"$(uname -r)
  echo -e "Architecture:\t\t"$(arch)
  echo -e "Processor Name:\t\t"$(cat /proc/cpuinfo | grep "model name" | uniq | sed -n 's/model name[[:space:]]*: //p')
  echo -e "CPU Cores:\t\t"$(dmidecode -t processor | grep "Core Count" | sed -n 's/[[:space:]]*Core Count:[[:space:]]*//p')
  echo -e "Active User:\t\t"$(w | cut -d ' ' -f1 | grep -v USER | xargs -n1)
  echo -e "System Main IP:\t\t"$(hostname -I)
  echo -e "Uptime:\t\t\t"$(uptime -p | sed 's/up //')
}

cpu_mem_usage() {
  echo -e "-------------------------------CPU/Memory Usage------------------------------"
  echo -e "Memory Usage:\t"`free | awk '/Mem/{printf("%.2f%"), $3/$2*100}'`
  echo -e "Swap Usage:\t"`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}'`
  echo -e "CPU Usage:\t"`cat /proc/stat | awk '/cpu/{printf("%.2f%\n"), ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}' | head -1`
  echo ""
  echo -e "-------------------------------Disk Usage >80%-------------------------------"
  df -Ph | sed s/%//g | awk '{ if($5 > 80) print $0;}'
}

wwn_details() {
  echo -e "-------------------------------For WWN Details-------------------------------"
  vserver=$(lscpu | grep Hypervisor | wc -l)
  if [ $vserver -gt 0 ]; then
    echo "$(hostname) is a VM"
  else
    cat /sys/class/fc_host/host?/port_name
  fi
}

oracle_db() {
  echo -e "-------------------------------Oracle DB Instances---------------------------"
  if id oracle >/dev/null 2>&1; then
    /bin/ps -ef|grep pmon
  else
    echo "oracle user does not exist on $(hostname)"
  fi
}

package_updates() {
  echo -e "-------------------------------Package Updates-------------------------------"
  if (( $(cat /etc/*-release | grep -w "Oracle|Red Hat|CentOS|Fedora" | wc -l) > 0 )); then
    yum updateinfo summary | grep 'Security|Bugfix|Enhancement'
    echo -e "-----------------------------------------------------------------------------"
  else
    cat /var/lib/update-notifier/updates-available
    echo -e "-----------------------------------------------------------------------------"
  fi
}

host_info
