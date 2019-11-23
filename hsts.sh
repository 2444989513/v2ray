#!/bin/bash

#====================================================
#	System Request:Debian 9+/Ubuntu 18.04+/Centos 7+
#	Author:	wulabing
#	Dscription: V2ray ws+tls onekey 
#	Version: 5.1
#	email:wulabing@admin.com
#	Official document: www.v2ray.com
#====================================================

#fonts color
Green="\033[32m" 
Red="\033[31m" 
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"

#notification information
Info="${Green}[��Ϣ]${Font}"
OK="${Green}[OK]${Font}"
Error="${Red}[����]${Font}"

v2ray_conf_dir="/etc/v2ray"
nginx_conf_dir="/etc/nginx/conf/conf.d"
v2ray_conf="${v2ray_conf_dir}/config.json"
nginx_conf="${nginx_conf_dir}/v2ray.conf"
nginx_dir="/etc/nginx"
nginx_openssl_src="/usr/local/src"
nginx_version="1.16.1"
openssl_version="1.1.1d"
#����αװ·��
camouflage=`cat /dev/urandom | head -n 10 | md5sum | head -c 8`

source /etc/os-release

#��VERSION����ȡ���а�ϵͳ��Ӣ�����ƣ�Ϊ����debian/ubuntu��������Ӧ��Nginx aptԴ
VERSION=`echo ${VERSION} | awk -F "[()]" '{print $2}'`

check_system(){
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]];then
        echo -e "${OK} ${GreenBG} ��ǰϵͳΪ Centos ${VERSION_ID} ${VERSION} ${Font}"
        INS="yum"
    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]];then
        echo -e "${OK} ${GreenBG} ��ǰϵͳΪ Debian ${VERSION_ID} ${VERSION} ${Font}"
        INS="apt"
        $INS update
        ## ��� Nginx aptԴ
    elif [[ "${ID}" == "ubuntu" && `echo "${VERSION_ID}" | cut -d '.' -f1` -ge 16 ]];then
        echo -e "${OK} ${GreenBG} ��ǰϵͳΪ Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        INS="apt"
        $INS update
    else
        echo -e "${Error} ${RedBG} ��ǰϵͳΪ ${ID} ${VERSION_ID} ����֧�ֵ�ϵͳ�б��ڣ���װ�ж� ${Font}"
        exit 1
    fi

    systemctl stop firewalld && systemctl disable firewalld
    echo -e "${OK} ${GreenBG} firewalld �ѹر� ${Font}"
}

is_root(){
    if [ `id -u` == 0 ]
        then echo -e "${OK} ${GreenBG} ��ǰ�û���root�û������밲װ���� ${Font}"
        sleep 3
    else
        echo -e "${Error} ${RedBG} ��ǰ�û�����root�û������л���root�û�������ִ�нű� ${Font}" 
        exit 1
    fi
}
judge(){
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} $1 ��� ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 ʧ��${Font}"
        exit 1
    fi
}
chrony_install(){
    ${INS} -y install chrony
    judge "��װ chrony ʱ��ͬ������ "

    timedatectl set-ntp true

    if [[ "${ID}" == "centos" ]];then
       systemctl enable chronyd && systemctl restart chronyd
    else
       systemctl enable chrony && systemctl restart chrony
    fi

    judge "chronyd ���� "

    timedatectl set-timezone Asia/Shanghai

    echo -e "${OK} ${GreenBG} �ȴ�ʱ��ͬ�� ${Font}"
    sleep 10

    chronyc sourcestats -v
    chronyc tracking -v
    date
    read -p "��ȷ��ʱ���Ƿ�׼ȷ,��Χ��3����(Y/N): " chrony_install
    [[ -z ${chrony_install} ]] && chrony_install="Y"
    case $chrony_install in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} ������װ ${Font}"
            sleep 2
            ;;
        *)
            echo -e "${RedBG} ��װ��ֹ ${Font}"
            exit 2
            ;;
        esac
}

dependency_install(){
    ${INS} install wget git lsof -y

    if [[ "${ID}" == "centos" ]];then
       ${INS} -y install crontabs
    else
       ${INS} -y install cron
    fi
    judge "��װ crontab"

    if [[ "${ID}" == "centos" ]];then
       touch /var/spool/cron/root && chmod 600 /var/spool/cron/root
       systemctl start crond && systemctl enable crond
    else
       touch /var/spool/cron/crontabs/root && chmod 600 /var/spool/cron/crontabs/root
       systemctl start cron && systemctl enable cron

    fi
    judge "crontab ���������� "



    ${INS} -y install bc
    judge "��װ bc"

    ${INS} -y install unzip
    judge "��װ unzip"

    ${INS} -y install qrencode
    judge "��װ qrencode"

    if [[ "${ID}" == "centos" ]];then
       ${INS} -y groupinstall "Development tools"
    else
       ${INS} -y install build-essential
    fi
    judge "���빤�߰� ��װ"

    if [[ "${ID}" == "centos" ]];then
       ${INS} -y install pcre pcre-devel zlib-devel
    else
       ${INS} -y install libpcre3 libpcre3-dev zlib1g-dev
    fi


    judge "nginx ����������װ"

}
basic_optimization(){
    # ����ļ�����
    sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    echo '* soft nofile 65536' >> /etc/security/limits.conf
    echo '* hard nofile 65536' >> /etc/security/limits.conf

    # �ر� Selinux
    if [[ "${ID}" == "centos" ]];then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
    fi

}
port_alterid_set(){
    read -p "���������Ӷ˿ڣ�default:443��:" port
    [[ -z ${port} ]] && port="443"
    read -p "������alterID��default:4��:" alterID
    [[ -z ${alterID} ]] && alterID="4"
}
modify_port_UUID(){
    let PORT=$RANDOM+10000
    UUID=$(cat /proc/sys/kernel/random/uuid)
    sed -i "/\"port\"/c  \    \"port\":${PORT}," ${v2ray_conf}
    sed -i "/\"id\"/c \\\t  \"id\":\"${UUID}\"," ${v2ray_conf}
    sed -i "/\"alterId\"/c \\\t  \"alterId\":${alterID}" ${v2ray_conf}
    sed -i "/\"path\"/c \\\t  \"path\":\"\/${camouflage}\/\"" ${v2ray_conf}
}
modify_nginx(){
    sed -i "1,/listen/{s/listen 443 ssl;/listen ${port} ssl;/}" ${nginx_conf}
    sed -i "/server_name/c \\\tserver_name ${domain};" ${nginx_conf}
    sed -i "/location/c \\\tlocation \/${camouflage}\/" ${nginx_conf}
    sed -i "/proxy_pass/c \\\tproxy_pass http://127.0.0.1:${PORT};" ${nginx_conf}
    sed -i "/return/c \\\treturn 301 https://${domain}\$request_uri;" ${nginx_conf}
    sed -i "27i \\\tproxy_intercept_errors on;"  ${nginx_dir}/conf/nginx.conf
}
web_camouflage(){
    ##��ע�� �����LNMP�ű���Ĭ��·����ͻ��ǧ��Ҫ�ڰ�װ��LNMP�Ļ�����ʹ�ñ��ű����������Ը�
    rm -rf /home/wwwroot && mkdir -p /home/wwwroot && cd /home/wwwroot
    git clone https://github.com/2444989513/250.git
    judge "web վ��αװ"   
}
v2ray_install(){
    if [[ -d /root/v2ray ]];then
        rm -rf /root/v2ray
    fi
    if [[ -d /etc/v2ray ]];then
        rm -rf /etc/v2ray
    fi
    mkdir -p /root/v2ray && cd /root/v2ray
    wget  --no-check-certificate https://install.direct/go.sh

    ## wget http://install.direct/go.sh
    
    if [[ -f go.sh ]];then
        bash go.sh --force
        judge "��װ V2ray"
    else
        echo -e "${Error} ${RedBG} V2ray ��װ�ļ�����ʧ�ܣ��������ص�ַ�Ƿ���� ${Font}"
        exit 4
    fi
    # �����ʱ�ļ�
    rm -rf /root/v2ray
}
nginx_install(){
    if [[ -d "/etc/nginx" ]];then
        rm -rf /etc/nginx
    fi

    wget -nc http://nginx.org/download/nginx-${nginx_version}.tar.gz -P ${nginx_openssl_src}
    judge "Nginx ����"
    wget -nc https://www.openssl.org/source/openssl-${openssl_version}.tar.gz -P ${nginx_openssl_src}
    judge "openssl ����"

    cd ${nginx_openssl_src}

    [[ -d nginx-"$nginx_version" ]] && rm -rf nginx-"$nginx_version"
    tar -zxvf nginx-"$nginx_version".tar.gz

    [[ -d openssl-"$openssl_version" ]] && rm -rf openssl-"$openssl_version"
    tar -zxvf openssl-"$openssl_version".tar.gz

    [[ -d "$nginx_dir" ]] && rm -rf ${nginx_dir}

    echo -e "${OK} ${GreenBG} ������ʼ���밲װ Nginx, �����Ծã������ĵȴ� ${Font}"
    sleep 4

    cd nginx-${nginx_version}
    ./configure --prefix="${nginx_dir}"                         \
            --with-http_ssl_module                              \
            --with-http_gzip_static_module                      \
            --with-http_stub_status_module                      \
            --with-pcre                                         \
            --with-http_realip_module                           \
            --with-http_flv_module                              \
            --with-http_mp4_module                              \
            --with-http_secure_link_module                      \
            --with-http_v2_module                               \
            --with-openssl=../openssl-"$openssl_version"
    judge "������"
    make && make install
    judge "Nginx ���밲װ"

    # �޸Ļ�������
    sed -i 's/#user  nobody;/user  root;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/worker_processes  1;/worker_processes  3;/' ${nginx_dir}/conf/nginx.conf
    sed -i 's/    worker_connections  1024;/    worker_connections  4096;/' ${nginx_dir}/conf/nginx.conf
    sed -i '$i include conf.d/*.conf;' ${nginx_dir}/conf/nginx.conf



    # ɾ����ʱ�ļ�
    rm -rf nginx-"${nginx_version}"
    rm -rf openssl-"${openssl_version}"
    rm -rf ../nginx-"${nginx_version}".tar.gz
    rm -rf ../openssl-"${openssl_version}".tar.gz

    # ��������ļ��У�����ɰ�ű�
    mkdir ${nginx_dir}/conf/conf.d
}
ssl_install(){
    if [[ "${ID}" == "centos" ]];then
        ${INS} install socat nc -y        
    else
        ${INS} install socat netcat -y
    fi
    judge "��װ SSL ֤�����ɽű�����"

    curl  https://get.acme.sh | sh
    judge "��װ SSL ֤�����ɽű�"
}
domain_check(){
    read -p "���������������Ϣ(eg:www.wulabing.com):" domain
    domain_ip=`ping ${domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    echo -e "${OK} ${GreenBG} ���ڻ�ȡ ����ip ��Ϣ�������ĵȴ� ${Font}"
    local_ip=`curl -4 ip.sb`
    echo -e "����dns����IP��${domain_ip}"
    echo -e "����IP: ${local_ip}"
    sleep 2
    if [[ $(echo ${local_ip}|tr '.' '+'|bc) -eq $(echo ${domain_ip}|tr '.' '+'|bc) ]];then
        echo -e "${OK} ${GreenBG} ����dns����IP  �� ����IP ƥ�� ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} ��ȷ�������������ȷ�� A ��¼�������޷�����ʹ�� V2ray"
        echo -e "${Error} ${RedBG} ����dns����IP �� ����IP ��ƥ�� �Ƿ������װ����y/n��${Font}" && read install
        case $install in
        [yY][eE][sS]|[yY])
            echo -e "${GreenBG} ������װ ${Font}" 
            sleep 2
            ;;
        *)
            echo -e "${RedBG} ��װ��ֹ ${Font}" 
            exit 2
            ;;
        esac
    fi
}

port_exist_check(){
    if [[ 0 -eq `lsof -i:"$1" | grep -i "listen" | wc -l` ]];then
        echo -e "${OK} ${GreenBG} $1 �˿�δ��ռ�� ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} ��⵽ $1 �˿ڱ�ռ�ã�����Ϊ $1 �˿�ռ����Ϣ ${Font}"
        lsof -i:"$1"
        echo -e "${OK} ${GreenBG} 5s �󽫳����Զ� kill ռ�ý��� ${Font}"
        sleep 5
        lsof -i:"$1" | awk '{print $2}'| grep -v "PID" | xargs kill -9
        echo -e "${OK} ${GreenBG} kill ��� ${Font}"
        sleep 1
    fi
}
acme(){
    ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 --force
    if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} SSL ֤�����ɳɹ� ${Font}"
        sleep 2
        mkdir /data
        ~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath /data/v2ray.crt --keypath /data/v2ray.key --ecc
        if [[ $? -eq 0 ]];then
        echo -e "${OK} ${GreenBG} ֤�����óɹ� ${Font}"
        sleep 2
        fi
    else
        echo -e "${Error} ${RedBG} SSL ֤������ʧ�� ${Font}"
        exit 1
    fi
}
v2ray_conf_add(){
    cd /etc/v2ray
    wget https://raw.githubusercontent.com/2444989513/V2ray/master/tls/config.json -O config.json
modify_port_UUID
judge "V2ray �����޸�"
}
nginx_conf_add(){
    touch ${nginx_conf_dir}/v2ray.conf
    cat>${nginx_conf_dir}/v2ray.conf<<EOF
	 server {
        listen 80;
        listen [::]:80;
        server_name serveraddr.com www.serveraddr.com;
	    return 301 https://$server_name$request_uri;
        
    }
	
    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl_certificate       /data/v2ray.crt;
        ssl_certificate_key   /data/v2ray.key;
        ssl_protocols         TLSv1.3;
        ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
	    add_header X-Frame-Options  DENY ;
		add_header X-Content-Type-Options  nosniff ;
		add_header X-Xss-Protection 1; 
		
        server_name           serveraddr.com www.serveraddr.com;
        index index.html index.htm;
        root  /home/wwwroot/250;
        error_page 400 = /400.html;
        location /ray/ 
        {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        }
}
   
EOF

modify_nginx
judge "Nginx �����޸�"

}

start_process_systemd(){
    ### nginx�����ڰ�װ��ɺ���Զ���������Ҫͨ��restart��reload���¼�������
    systemctl restart nginx
    judge "Nginx ����"

    systemctl enable nginx
    judge "���� Nginx ��������"

    systemctl restart v2ray
    judge "V2ray ����"

    systemctl enable v2ray
    judge "���� v2ray ��������"
}

#debian ϵ 9 10 ����
#rc_local_initialization(){
#    if [[ -f /etc/rc.local ]];then
#        chmod +x /etc/rc.local
#    else
#        touch /etc/rc.local && chmod +x /etc/rc.local
#        echo "#!/bin/bash" >> /etc/rc.local
#        systemctl start rc-local
#    fi
#
#    judge "rc.local ����"
#}
acme_cron_update(){
    if [[ "${ID}" == "centos" ]];then
        sed -i "/acme.sh/c 0 0 * * 0 systemctl stop nginx && \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
        > /dev/null && systemctl start nginx" /var/spool/cron/root
    else
        sed -i "/acme.sh/c 0 0 * * 0 systemctl stop nginx && \"/root/.acme.sh\"/acme.sh --cron --home \"/root/.acme.sh\" \
        > /dev/null && systemctl start nginx" /var/spool/cron/crontabs/root
    fi
    judge "cron �ƻ��������"
}

vmess_qr_config(){
    cat >/etc/v2ray/vmess_qr.json <<-EOF
    {
        "v": "2",
        "ps": "wulabing_${domain}",
        "add": "${domain}",
        "port": "${port}",
        "id": "${UUID}",
        "aid": "${alterID}",
        "net": "ws",
        "type": "none",
        "host": "${domain}",
        "path": "/${camouflage}/",
        "tls": "tls"
    }
EOF

    vmess_link="vmess://$(cat /etc/v2ray/vmess_qr.json | base64 -w 0)"
    echo -e "${Red} URL��������:${vmess_link} ${Font}" >>./v2ray_info.txt
    echo -e "${Red} ��ά��: ${Font}" >>./v2ray_info.txt
    echo "${vmess_link}"| qrencode -o - -t utf8 >>./v2ray_info.txt
}

show_information(){
    clear
    cd ~

    echo -e "${OK} ${Green} V2ray+ws+tls ��װ�ɹ�" >./v2ray_info.txt
    echo -e "${Red} V2ray ������Ϣ ${Font}" >>./v2ray_info.txt
    echo -e "${Red} ��ַ��address��:${Font} ${domain} " >>./v2ray_info.txt
    echo -e "${Red} �˿ڣ�port����${Font} ${port} " >>./v2ray_info.txt
    echo -e "${Red} �û�id��UUID����${Font} ${UUID}" >>./v2ray_info.txt
    echo -e "${Red} ����id��alterId����${Font} ${alterID}" >>./v2ray_info.txt
    echo -e "${Red} ���ܷ�ʽ��security����${Font} ����Ӧ " >>./v2ray_info.txt
    echo -e "${Red} ����Э�飨network����${Font} ws " >>./v2ray_info.txt
    echo -e "${Red} αװ���ͣ�type����${Font} none " >>./v2ray_info.txt
    echo -e "${Red} ·������Ҫ����/����${Font} /${camouflage}/ " >>./v2ray_info.txt
    echo -e "${Red} �ײ㴫�䰲ȫ��${Font} tls " >>./v2ray_info.txt
    vmess_qr_config
    cat ./v2ray_info.txt

}
ssl_judge_and_install(){
    if [[ -f "/data/v2ray.key" && -f "/data/v2ray.crt" ]];then
        echo "֤���ļ��Ѵ���"
    elif [[ -f "~/.acme.sh/${domain}_ecc/${domain}.key" && -f "~/.acme.sh/${domain}_ecc/${domain}.cer" ]];then
        echo "֤���ļ��Ѵ���"
        ~/.acme.sh/acme.sh --installcert -d ${domain} --fullchainpath /data/v2ray.crt --keypath /data/v2ray.key --ecc
        judge "֤��Ӧ��"
    else
        ssl_install
        acme
    fi
}
nginx_systemd(){
    cat>/lib/systemd/system/nginx.service<<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/etc/nginx/logs/nginx.pid
ExecStartPre=/etc/nginx/sbin/nginx -t
ExecStart=/etc/nginx/sbin/nginx -c ${nginx_dir}/conf/nginx.conf
ExecReload=/etc/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

judge "Nginx systemd ServerFile ���"
}
main(){
    is_root
    check_system
    chrony_install
    dependency_install
    basic_optimization
    domain_check
    port_alterid_set
    v2ray_install
    port_exist_check 80
    port_exist_check ${port}
    nginx_install
    v2ray_conf_add
    nginx_conf_add
    web_camouflage

    #��֤�����ɷ�����󣬾��������γ��Խű��Ӷ���ɵĶ��֤������
    ssl_judge_and_install
    nginx_systemd
    show_information
    start_process_systemd
    acme_cron_update
}

main