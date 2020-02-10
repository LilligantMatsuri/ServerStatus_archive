#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#==============================================================
#	Required System: CentOS 7+ / Debian 8+ / Ubuntu 15.04+
#	Description: ServerStatus deployment & management
#	Version: 2.0.0 (systemd)
#	Author: Toyo
#	Maintainer: Matsuri
#==============================================================

sh_ver="2.0.0"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
file="/usr/local/ServerStatus"
web_file="/usr/local/ServerStatus/web"
server_file="/usr/local/ServerStatus/server"
server_json="/usr/local/ServerStatus/server/config.json"
server_conf="/usr/local/ServerStatus/server/config.conf"
client_file="/usr/local/ServerStatus/client"
client_log_file="/tmp/serverstatus_client.log"
server_log_file="/tmp/serverstatus_server.log"
jq_file="${file}/jq"

Red_font_prefix="\033[31m" && Green_font_prefix="\033[32m" && Yellow_font_prefix="\033[33m" && Red_background_prefix="\033[41;37m" && Green_background_prefix="\033[42;37m" && Yellow_background_prefix="\033[43;37m" && Font_color_suffix="\033[0m"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[提示]${Font_color_suffix}"

#检查
check_sys(){
	if [[ -f /etc/centos-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
    fi
	bit=`uname -m`
}
check_installed_server_status(){
	[[ ! -e "${server_file}/sergate" ]] && echo -e "${Error} ServerStatus 服务端未安装，请检查！\n" && exit 1
}
check_installed_client_status(){
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		if [[ ! -e "${file}/status-client.py" ]]; then
			echo -e "${Error} ServerStatus 客户端未安装，请检查！\n" && exit 1
		fi
	fi
}
check_pid_server(){
	PID=`ps -e | grep "sergate" | awk '{print $1}'`
}
check_pid_client(){
	PID=`ps aux | grep "status-client.py" | grep -v grep | awk '{print $2}'`
}

#下载
Download_Server_Status_server(){
	cd "/tmp"
	wget -N --no-check-certificate "https://github.com/LilligantMatsuri/ServerStatus/archive/master.zip"
	[[ ! -e "master.zip" ]] && echo -e "${Error} ServerStatus 服务端文件下载失败！\n" && exit 1
	unzip master.zip
	rm -rf master.zip
	[[ ! -e "/tmp/ServerStatus-master" ]] && echo -e "${Error} ServerStatus 服务端文件解压失败！\n" && exit 1
	cd "/tmp/ServerStatus-master/server"
	make
	[[ ! -e "sergate" ]] && echo -e "${Error} ServerStatus 服务端编译失败！\n" && cd "${file_1}" && rm -rf "/tmp/ServerStatus-master" && exit 1
	cd "${file_1}"
	[[ ! -e "${file}" ]] && mkdir "${file}"
	if [[ ! -e "${server_file}" ]]; then
		mkdir "${server_file}"
		mv "/tmp/ServerStatus-master/server/sergate" "${server_file}/sergate"
		mv "/tmp/ServerStatus-master/web" "${web_file}"
	else
		if [[ -e "${server_file}/sergate" ]]; then
			mv "${server_file}/sergate" "${server_file}/sergate1"
			mv "/tmp/ServerStatus-master/server/sergate" "${server_file}/sergate"
		else
			mv "/tmp/ServerStatus-master/server/sergate" "${server_file}/sergate"
			mv "/tmp/ServerStatus-master/web" "${web_file}"
		fi
	fi
	if [[ ! -e "${server_file}/sergate" ]]; then
		echo -e "${Error} ServerStatus 服务端文件移动失败！\n"
		[[ -e "${server_file}/sergate1" ]] && mv "${server_file}/sergate1" "${server_file}/sergate"
		rm -rf "/tmp/ServerStatus-master"
		exit 1
	else
		[[ -e "${server_file}/sergate1" ]] && rm -rf "${server_file}/sergate1"
		rm -rf "/tmp/ServerStatus-master"
	fi
}
Download_Server_Status_client(){
	cd "/tmp"
	wget -N --no-check-certificate "https://raw.githubusercontent.com/LilligantMatsuri/ServerStatus/master/client/status-client.py"
	[[ ! -e "status-client.py" ]] && echo -e "${Error} ServerStatus 客户端文件下载失败！\n" && exit 1
	cd "${file_1}"
	[[ ! -e "${file}" ]] && mkdir "${file}"
	if [[ ! -e "${client_file}" ]]; then
		mkdir "${client_file}"
		mv "/tmp/status-client.py" "${client_file}/status-client.py"
	else
		if [[ -e "${client_file}/status-client.py" ]]; then
			mv "${client_file}/status-client.py" "${client_file}/status-client1.py"
			mv "/tmp/status-client.py" "${client_file}/status-client.py"
		else
			mv "/tmp/status-client.py" "${client_file}/status-client.py"
		fi
	fi
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		echo -e "${Error} ServerStatus 客户端文件移动失败！\n"
		[[ -e "${client_file}/status-client1.py" ]] && mv "${client_file}/status-client1.py" "${client_file}/status-client.py"
		rm -rf "/tmp/status-client.py"
		exit 1
	else
		[[ -e "${client_file}/status-client1.py" ]] && rm -rf "${client_file}/status-client1.py"
		rm -rf "/tmp/status-client.py"
	fi
}
Service_Server_Status_server(){
	if ! wget --no-check-certificate "https://raw.githubusercontent.com/LilligantMatsuri/ServerStatus/master/script/status-server.service" -O /usr/lib/systemd/system/status-server.service; then
		echo -e "${Error} ServerStatus 服务端服务管理脚本下载失败！\n" && exit 1
	fi
	chmod +x /usr/lib/systemd/system/status-server.service
	systemctl daemon-reload
	systemctl enable status-server
	echo -e "${Info} ServerStatus 服务端服务管理脚本下载完成！"
}
Service_Server_Status_client(){
	if ! wget --no-check-certificate "https://raw.githubusercontent.com/LilligantMatsuri/ServerStatus/master/script/status-client.service" -O /usr/lib/systemd/system/status-client.service; then
		echo -e "${Error} ServerStatus 客户端服务管理脚本下载失败！\n" && exit 1
	fi
	chmod +x /usr/lib/systemd/system/status-client.service
	systemctl daemon-reload
	systemctl enable status-client
	echo -e "${Info} ServerStatus 客户端服务管理脚本下载完成！"
}
Installation_dependency(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		if [[ ${release} == "centos" ]]; then
			yum update
			yum install -y unzip vim make net-tools
			yum groupinstall "Development Tools" -y
		else
			apt-get update
			apt-get install -y unzip vim build-essential make
		fi
	fi
}
Installation_Python(){
	py_ver=$(python -V 2>&1 | awk '{print $2}' | awk -F '.' '{print $1}')
	if [[ ${release} == "centos" ]]; then
	centos_ver=$(cat /etc/redhat-release | grep "release " | awk '{print $4}' | awk -F '.' '{print $1}')
		if [[ ${centos_ver} -ge 8 ]]; then
			if [[ -z ${py_ver} ]]; then
				echo -e "${Info} 您正在使用的 CentOS 未安装 Python，将为您安装 Python 2.7 并设置为默认版本"
				yum install -y python2
				alternatives --set python /usr/bin/python2
			fi
		else
			if [[ -z ${py_ver} ]]; then
				yum install -y python
			fi
		fi
	else
		if [[ -z ${py_ver} ]]; then
			apt-get install -y python
		fi
	fi
}

#配置
Write_server_config(){
	cat > ${server_json}<<-EOF
{"servers":
 [
  {
   "username": "Username",
   "password": "Password",
   "name": "Node 1",
   "type": "KVM",
   "host": "",
   "location": "China",
   "disabled": false
  }
 ]
}
EOF
}
Write_server_config_conf(){
	cat > ${server_conf}<<-EOF
PORT = ${server_port_s}
EOF
}
Read_config_client(){
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		if [[ ! -e "${file}/status-client.py" ]]; then
			echo -e "${Error} ServerStatus 客户端文件不存在！\n" && exit 1
		else
			client_text="$(cat "${file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
			rm -rf "${file}/status-client.py"
		fi
	else
		client_text="$(cat "${client_file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
	fi
	client_server="$(echo -e "${client_text}"|grep "SERVER="|awk -F "=" '{print $2}')"
	client_port="$(echo -e "${client_text}"|grep "PORT="|awk -F "=" '{print $2}')"
	client_user="$(echo -e "${client_text}"|grep "USER="|awk -F "=" '{print $2}')"
	client_password="$(echo -e "${client_text}"|grep "PASSWORD="|awk -F "=" '{print $2}')"
}
Read_config_server(){
	if [[ ! -e "${server_conf}" ]]; then
		server_port_s="35601"
		Write_server_config_conf
		server_port="35601"
	else
		server_port="$(cat "${server_conf}"|grep "PORT = "|awk '{print $3}')"
	fi
}
Set_server(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		echo -e "${Tip} 请输入服务端网站的域名[server]，如果留空则默认使用本机 IP 地址"
		read -e -p "(默认: 本机 IP):" server_s
		[[ -z "$server_s" ]] && server_s=""
	else
		echo -e "${Tip} 请输入服务端的 IP/域名[server]"
		read -e -p "(默认: 127.0.0.1):" server_s
		[[ -z "$server_s" ]] && server_s="127.0.0.1"
	fi
	
	echo && echo "	================================================"
	echo -e "	IP/域名[server]: ${Red_background_prefix} ${server_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_server_http_port(){
	while true
		do
		echo -e "${Tip} 请输入服务端网站的端口号[1-65535]（如需绑定域名，通常使用 80 端口）"
		read -e -p "(默认: 8888):" server_http_port_s
		[[ -z "$server_http_port_s" ]] && server_http_port_s="8888"
		echo $((${server_http_port_s}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${server_http_port_s} -ge 1 ]] && [[ ${server_http_port_s} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	端口: ${Red_background_prefix} ${server_http_port_s} ${Font_color_suffix}"
				echo "	================================================" && echo
				break
			else
				echo -e "${Error} 请输入有效的端口号！"
			fi
		else
			echo -e "${Error} 请输入有效的端口号！"
		fi
	done
}
Set_server_port(){
	while true
		do
		echo -e "${Tip} 请输入服务端的监听端口[1-65535]\n（用于服务端接收客户端数据，安装客户端时需要填写此端口）"
		read -e -p "(默认: 35601):" server_port_s
		[[ -z "$server_port_s" ]] && server_port_s="35601"
		echo $((${server_port_s}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${server_port_s} -ge 1 ]] && [[ ${server_port_s} -le 65535 ]]; then
				echo && echo "	================================================"
				echo -e "	端口: ${Red_background_prefix} ${server_port_s} ${Font_color_suffix}"
				echo "	================================================" && echo
				break
			else
				echo -e "${Error} 请输入有效的端口号！"
			fi
		else
			echo -e "${Error} 请输入有效的端口号！"
		fi
	done
}
Set_username(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		echo -e "${Tip} 请输入客户端的用户名[username]（字母/数字，不可与其他配置重复）"
	else
		echo -e "${Tip} 请输入服务端设置的用户名[username]（字母/数字）"
	fi
	read -e -p "(默认: 取消):" username_s
	[[ -z "$username_s" ]] && echo -e "${Info} 已取消...\n" && exit 0
	echo && echo "	================================================"
	echo -e "	用户名[username]: ${Red_background_prefix} ${username_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_password(){
	mode=$1
	[[ -z ${mode} ]] && mode="server"
	if [[ ${mode} == "server" ]]; then
		echo -e "${Tip} 请输入客户端的密码[password]（字母/数字，可以与其他配置重复）"
	else
		echo -e "${Tip} 请输入服务端设置的密码[password]（字母/数字）"
	fi
	read -e -p "(默认: Password):" password_s
	[[ -z "$password_s" ]] && password_s="Password"
	echo && echo "	================================================"
	echo -e "	密码[password]: ${Red_background_prefix} ${password_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_name(){
	echo -e "${Tip} 请输入客户端的节点名称[name]（内容随意，可以为中文）"
	read -e -p "(默认: Node 1):" name_s
	[[ -z "$name_s" ]] && name_s="Node 1"
	echo && echo "	================================================"
	echo -e "	节点名称[name]: ${Red_background_prefix} ${name_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_type(){
	echo -e "${Tip} 请输入客户端的虚拟化类型[type]（内容随意，如 OpenVZ、KVM 等）"
	read -e -p "(默认: KVM):" type_s
	[[ -z "$type_s" ]] && type_s="KVM"
	echo && echo "	================================================"
	echo -e "	虚拟化类型[type]: ${Red_background_prefix} ${type_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_location(){
	echo -e "${Tip} 请输入客户端的节点位置[location]（内容随意，可以为中文）"
	read -e -p "(默认: China):" location_s
	[[ -z "$location_s" ]] && location_s="China"
	echo && echo "	================================================"
	echo -e "	节点位置[location]: ${Red_background_prefix} ${location_s} ${Font_color_suffix}"
	echo "	================================================" && echo
}
Set_config_server(){
	Set_username "server"
	Set_password "server"
	Set_name
	Set_type
	Set_location
}
Set_config_client(){
	Set_server "client"
	Set_server_port
	Set_username "client"
	Set_password "client"
}
Set_ServerStatus_server(){
	check_installed_server_status
	echo && echo -e " 您要做什么？（请输入选项的编号）
	
 ${Green_font_prefix} 1.${Font_color_suffix} 添加 节点配置
 ${Green_font_prefix} 2.${Font_color_suffix} 删除 节点配置
————————————————
 ${Green_font_prefix} 3.${Font_color_suffix} 修改 节点配置 - 用户名
 ${Green_font_prefix} 4.${Font_color_suffix} 修改 节点配置 - 密码
 ${Green_font_prefix} 5.${Font_color_suffix} 修改 节点配置 - 名称
 ${Green_font_prefix} 6.${Font_color_suffix} 修改 节点配置 - 虚拟化
 ${Green_font_prefix} 7.${Font_color_suffix} 修改 节点配置 - 位置
 ${Green_font_prefix} 8.${Font_color_suffix} 修改 节点配置 - 全部参数
————————————————
 ${Green_font_prefix} 9.${Font_color_suffix} 启用/禁用 节点配置
————————————————
 ${Green_font_prefix}10.${Font_color_suffix} 修改 服务端监听端口" && echo
	read -e -p "(默认: 取消):" server_num
	[[ -z "${server_num}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	if [[ ${server_num} == "1" ]]; then
		Add_ServerStatus_server
	elif [[ ${server_num} == "2" ]]; then
		Del_ServerStatus_server
	elif [[ ${server_num} == "3" ]]; then
		Modify_ServerStatus_server_username
	elif [[ ${server_num} == "4" ]]; then
		Modify_ServerStatus_server_password
	elif [[ ${server_num} == "5" ]]; then
		Modify_ServerStatus_server_name
	elif [[ ${server_num} == "6" ]]; then
		Modify_ServerStatus_server_type
	elif [[ ${server_num} == "7" ]]; then
		Modify_ServerStatus_server_location
	elif [[ ${server_num} == "8" ]]; then
		Modify_ServerStatus_server_all
	elif [[ ${server_num} == "9" ]]; then
		Modify_ServerStatus_server_disabled
	elif [[ ${server_num} == "10" ]]; then
		Read_config_server
		Del_iptables "${server_port}"
		Set_server_port
		Write_server_config_conf
		Add_iptables "${server_port_s}"
	else
		echo -e "${Error} 请输入有效的编号[1-10]！\n" && exit 1
	fi
	Restart_ServerStatus_server
}
List_ServerStatus_server(){
	conf_text=$(${jq_file} '.servers' ${server_json}|${jq_file} ".[]|.username"|sed 's/\"//g')
	conf_text_total=$(echo -e "${conf_text}"|wc -l)
	[[ ${conf_text_total} = "0" ]] && echo -e "${Error} 没有发现节点配置，请检查！\n" && exit 1
	conf_text_total_a=$(echo $((${conf_text_total}-1)))
	conf_list_all=""
	for((integer = 0; integer <= ${conf_text_total_a}; integer++))
	do
		now_text=$(${jq_file} '.servers' ${server_json}|${jq_file} ".[${integer}]"|sed 's/\"//g;s/,$//g'|sed '$d;1d')
		now_text_username=$(echo -e "${now_text}"|grep "username"|awk -F ": " '{print $2}')
		now_text_password=$(echo -e "${now_text}"|grep "password"|awk -F ": " '{print $2}')
		now_text_name=$(echo -e "${now_text}"|grep "name"|grep -v "username"|awk -F ": " '{print $2}')
		now_text_type=$(echo -e "${now_text}"|grep "type"|awk -F ": " '{print $2}')
		now_text_location=$(echo -e "${now_text}"|grep "location"|awk -F ": " '{print $2}')
		now_text_disabled=$(echo -e "${now_text}"|grep "disabled"|awk -F ": " '{print $2}')
		if [[ ${now_text_disabled} == "false" ]]; then
			now_text_disabled_status="${Green_font_prefix}启用${Font_color_suffix}"
		else
			now_text_disabled_status="${Red_font_prefix}禁用${Font_color_suffix}"
		fi
		conf_list_all=${conf_list_all}"用户名: ${Green_font_prefix}"${now_text_username}"${Font_color_suffix} 密码: ${Green_font_prefix}"${now_text_password}"${Font_color_suffix} 名称: ${Green_font_prefix}"${now_text_name}"${Font_color_suffix} 虚拟化: ${Green_font_prefix}"${now_text_type}"${Font_color_suffix} 位置: ${Green_font_prefix}"${now_text_location}"${Font_color_suffix} 状态: ${Green_font_prefix}"${now_text_disabled_status}"${Font_color_suffix}\n"
	done
	echo && echo -e "节点总数: ${Green_font_prefix}"${conf_text_total}"${Font_color_suffix}"
	echo -e "————————————————"
	echo -e ${conf_list_all}
}
Add_ServerStatus_server(){
	Set_config_server
	Set_username_ch=$(cat ${server_json}|grep '"username": "'"${username_s}"'"')
	[[ ! -z "${Set_username_ch}" ]] && echo -e "${Error} 此用户名已被使用！\n" && exit 1
	sed -i '3i\  },' ${server_json}
	sed -i '3i\   "disabled": false' ${server_json}
	sed -i '3i\   "location": "'"${location_s}"'",' ${server_json}
	sed -i '3i\   "host": "'"None"'",' ${server_json}
	sed -i '3i\   "type": "'"${type_s}"'",' ${server_json}
	sed -i '3i\   "name": "'"${name_s}"'",' ${server_json}
	sed -i '3i\   "password": "'"${password_s}"'",' ${server_json}
	sed -i '3i\   "username": "'"${username_s}"'",' ${server_json}
	sed -i '3i\  {' ${server_json}
	echo -e "${Info} 配置添加成功！${Green_font_prefix}[ 名称: ${name_s}, 用户名: ${username_s}, 密码: ${password_s} ]${Font_color_suffix}"
}
Del_ServerStatus_server(){
	List_ServerStatus_server
	[[ "${conf_text_total}" = "1" ]] && echo -e "${Error} 仅剩一个节点配置，不能删除！\n" && exit 1
	echo -e "${Tip} 请输入需要删除的节点的用户名"
	read -e -p "(默认: 取消):" del_server_username
	[[ -z "${del_server_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	del_username=`cat -n ${server_json}|grep '"username": "'"${del_server_username}"'"'|awk '{print $1}'`
	if [[ ! -z ${del_username} ]]; then
		del_username_min=$(echo $((${del_username}-1)))
		del_username_max=$(echo $((${del_username}+7)))
		del_username_max_text=$(sed -n "${del_username_max}p" ${server_json})
		del_username_max_text_last=`echo ${del_username_max_text:((${#del_username_max_text} - 1))}`
		if [[ ${del_username_max_text_last} != "," ]]; then
			del_list_num=$(echo $((${del_username_min}-1)))
			sed -i "${del_list_num}s/,$//g" ${server_json}
		fi
		sed -i "${del_username_min},${del_username_max}d" ${server_json}
		echo -e "${Info} 配置删除成功！${Green_font_prefix}[ 用户名: ${del_server_username} ]${Font_color_suffix}"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Modify_ServerStatus_server_username(){
	List_ServerStatus_server
	echo -e "${Tip} 请输入需要修改的节点的用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	Set_username_num=$(cat -n ${server_json}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_username
		Set_username_ch=$(cat ${server_json}|grep '"username": "'"${username_s}"'"')
		[[ ! -z "${Set_username_ch}" ]] && echo -e "${Error} 此用户名已被使用！\n" && exit 1
		sed -i "${Set_username_num}"'s/"username": "'"${manually_username}"'"/"username": "'"${username_s}"'"/g' ${server_json}
		echo -e "${Info} 配置修改成功！${Green_font_prefix}[ 原用户名: ${manually_username}, 新用户名: ${username_s} ]${Font_color_suffix}"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Modify_ServerStatus_server_password(){
	List_ServerStatus_server
	echo -e "${Tip} 请输入需要修改的节点的用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	Set_username_num=$(cat -n ${server_json}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_password
		Set_password_num_a=$(echo $((${Set_username_num}+1)))
		Set_password_num_text=$(sed -n "${Set_password_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_password_num_a}"'s/"password": "'"${Set_password_num_text}"'"/"password": "'"${password_s}"'"/g' ${server_json}
		echo -e "${Info} 配置修改成功！${Green_font_prefix}[ 原密码: ${Set_password_num_text}, 新密码: ${password_s} ]${Font_color_suffix}"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Modify_ServerStatus_server_name(){
	List_ServerStatus_server
	echo -e "${Tip} 请输入需要修改的节点的用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	Set_username_num=$(cat -n ${server_json}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_name
		Set_name_num_a=$(echo $((${Set_username_num}+2)))
		Set_name_num_a_text=$(sed -n "${Set_name_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_name_num_a}"'s/"name": "'"${Set_name_num_a_text}"'"/"name": "'"${name_s}"'"/g' ${server_json}
		echo -e "${Info} 配置修改成功！${Green_font_prefix}[ 原名称: ${Set_name_num_a_text}, 新名称: ${name_s} ]${Font_color_suffix}"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Modify_ServerStatus_server_type(){
	List_ServerStatus_server
	echo -e "${Tip} 请输入需要修改的节点的用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	Set_username_num=$(cat -n ${server_json}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_type
		Set_type_num_a=$(echo $((${Set_username_num}+3)))
		Set_type_num_a_text=$(sed -n "${Set_type_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_type_num_a}"'s/"type": "'"${Set_type_num_a_text}"'"/"type": "'"${type_s}"'"/g' ${server_json}
		echo -e "${Info} 配置修改成功！${Green_font_prefix}[ 原类型: ${Set_type_num_a_text}, 新类型: ${type_s} ]${Font_color_suffix}"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Modify_ServerStatus_server_location(){
	List_ServerStatus_server
	echo -e "${Tip} 请输入需要修改的节点的用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	Set_username_num=$(cat -n ${server_json}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_location
		Set_location_num_a=$(echo $((${Set_username_num}+5)))
		Set_location_num_a_text=$(sed -n "${Set_location_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_location_num_a}"'s/"location": "'"${Set_location_num_a_text}"'"/"location": "'"${location_s}"'"/g' ${server_json}
		echo -e "${Info} 配置修改成功！${Green_font_prefix}[ 原位置: ${Set_location_num_a_text}, 新位置: ${location_s} ]${Font_color_suffix}"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Modify_ServerStatus_server_all(){
	List_ServerStatus_server
	echo -e "${Tip} 请输入需要修改的节点的用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	Set_username_num=$(cat -n ${server_json}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_username
		Set_password
		Set_name
		Set_type
		Set_location
		sed -i "${Set_username_num}"'s/"username": "'"${manually_username}"'"/"username": "'"${username_s}"'"/g' ${server_json}
		Set_password_num_a=$(echo $((${Set_username_num}+1)))
		Set_password_num_text=$(sed -n "${Set_password_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_password_num_a}"'s/"password": "'"${Set_password_num_text}"'"/"password": "'"${password_s}"'"/g' ${server_json}
		Set_name_num_a=$(echo $((${Set_username_num}+2)))
		Set_name_num_a_text=$(sed -n "${Set_name_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_name_num_a}"'s/"name": "'"${Set_name_num_a_text}"'"/"name": "'"${name_s}"'"/g' ${server_json}
		Set_type_num_a=$(echo $((${Set_username_num}+3)))
		Set_type_num_a_text=$(sed -n "${Set_type_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_type_num_a}"'s/"type": "'"${Set_type_num_a_text}"'"/"type": "'"${type_s}"'"/g' ${server_json}
		Set_location_num_a=$(echo $((${Set_username_num}+5)))
		Set_location_num_a_text=$(sed -n "${Set_location_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		sed -i "${Set_location_num_a}"'s/"location": "'"${Set_location_num_a_text}"'"/"location": "'"${location_s}"'"/g' ${server_json}
		echo -e "${Info} 配置修改成功！"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Modify_ServerStatus_server_disabled(){
	List_ServerStatus_server
	echo -e "${Tip} 请输入需要修改的节点的用户名"
	read -e -p "(默认: 取消):" manually_username
	[[ -z "${manually_username}" ]] && echo -e "${Info} 已取消...\n" && exit 1
	Set_username_num=$(cat -n ${server_json}|grep '"username": "'"${manually_username}"'"'|awk '{print $1}')
	if [[ ! -z ${Set_username_num} ]]; then
		Set_disabled_num_a=$(echo $((${Set_username_num}+6)))
		Set_disabled_num_a_text=$(sed -n "${Set_disabled_num_a}p" ${server_json}|sed 's/\"//g;s/,$//g'|awk -F ": " '{print $2}')
		if [[ ${Set_disabled_num_a_text} == "false" ]]; then
			disabled_s="true"
		else
			disabled_s="false"
		fi
		sed -i "${Set_disabled_num_a}"'s/"disabled": '"${Set_disabled_num_a_text}"'/"disabled": '"${disabled_s}"'/g' ${server_json}
		echo -e "${Info} 配置修改成功！${Green_font_prefix}[ 原状态: ${Set_disabled_num_a_text}, 新状态: ${disabled_s} ]${Font_color_suffix}"
	else
		echo -e "${Error} 请输入有效的用户名！\n" && exit 1
	fi
}
Set_ServerStatus_client(){
	check_installed_client_status
	Set_config_client
	Read_config_client
	Del_iptables_OUT "${client_port}"
	Modify_config_client
	Add_iptables_OUT "${server_port_s}"
	Restart_ServerStatus_client
}
Modify_config_client(){
	sed -i 's/SERVER = "'"${client_server}"'"/SERVER = "'"${server_s}"'"/g' "${client_file}/status-client.py"
	sed -i "s/PORT = ${client_port}/PORT = ${server_port_s}/g" "${client_file}/status-client.py"
	sed -i 's/USER = "'"${client_user}"'"/USER = "'"${username_s}"'"/g' "${client_file}/status-client.py"
	sed -i 's/PASSWORD = "'"${client_password}"'"/PASSWORD = "'"${password_s}"'"/g' "${client_file}/status-client.py"
}

#安装
Install_jq(){
	if [[ ! -e ${jq_file} ]]; then
		if [[ ${bit} = "x86_64" ]]; then
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" -O ${jq_file}
		else
			wget --no-check-certificate "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux32" -O ${jq_file}
		fi
		[[ ! -e ${jq_file} ]] && echo -e "${Error} jq 下载失败，请检查！\n" && exit 1
		chmod +x ${jq_file}
		echo -e "${Info} jq 安装完成，继续..." 
	else
		echo -e "${Info} jq 已安装，继续..."
	fi
}
Install_caddy(){
	echo
	echo -e "${Tip} 是否需要自动部署 HTTP 服务（服务端网站）？\n如果选择 n，请在其他 HTTP 服务器中配置网站根目录为：${Green_font_prefix}${web_file}${Font_color_suffix} [Y/n]"
	read -e -p "(默认: y 自动部署):" caddy_yn
	[[ -z "$caddy_yn" ]] && caddy_yn="y"
	if [[ "${caddy_yn}" == [Yy] ]]; then
		Set_server "server"
		Set_server_http_port
		if [[ ! -e "/usr/local/caddy/caddy" ]]; then
			wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh
			chmod +x caddy_install.sh
			bash caddy_install.sh install
			rm -rf caddy_install.sh
			[[ ! -e "/usr/local/caddy/caddy" ]] && echo -e "${Error} Caddy 安装失败，请手动部署\n" && exit 1
		else
			echo -e "${Info} Caddy 已安装，开始配置..."
		fi
		if [[ ! -s "/usr/local/caddy/Caddyfile" ]]; then
			cat > "/usr/local/caddy/Caddyfile"<<-EOF
http://${server_s}:${server_http_port_s} {
 root ${web_file}
 timeouts none
 gzip
}
EOF
			/etc/init.d/caddy restart
		else
			echo -e "${Info} Caddy 配置文件存在内容，ServerStatus 网站配置将追加在末尾"
			cat >> "/usr/local/caddy/Caddyfile"<<-EOF
http://${server_s}:${server_http_port_s} {
 root ${web_file}
 timeouts none
 gzip
}
EOF
			/etc/init.d/caddy restart
		fi
	else
		echo -e "${Info} HTTP 服务部署已跳过，请手动部署。Web 文件位置：${Green_font_prefix}${web_file}${Font_color_suffix}"
	fi
}
Install_ServerStatus_server(){
	[[ -e "${server_file}/sergate" ]] && echo -e "${Error} 检测到 ServerStatus 服务端已安装！\n" && exit 1
	Set_server_port
	echo -e "${Info} 正在下载安装依赖..."
	Installation_dependency "server"
	Installation_Python
	Install_caddy
	echo -e "${Info} 正在下载安装服务端..."
	Download_Server_Status_server
	Install_jq
	echo -e "${Info} 正在下载安装服务脚本(systemd)..."
	Service_Server_Status_server
	echo -e "${Info} 正在写入服务端配置..."
	Write_server_config
	Write_server_config_conf
	echo -e "${Info} 正在配置 Iptables 防火墙..."
	Set_iptables
	echo -e "${Info} 正在添加 Iptables 规则..."
	Add_iptables "${server_port_s}"
	[[ ! -z "${server_http_port_s}" ]] && Add_iptables "${server_http_port_s}"
	echo -e "${Info} 正在保存 Iptables 规则..."
	Save_iptables
	echo -e "${Info} 所有步骤执行完毕，正在启动服务端..."
	Start_ServerStatus_server
}
Install_ServerStatus_client(){
	[[ -e "${client_file}/status-client.py" ]] && echo -e "${Error} 检测到 ServerStatus 客户端已安装！\n" && exit 1
	echo -e "${Info} 正在设置用户配置..."
	Set_config_client
	echo -e "${Info} 正在下载安装依赖..."
	Installation_dependency "client"
	Installation_Python
	echo -e "${Info} 正在下载安装客户端..."
	Download_Server_Status_client
	echo -e "${Info} 开始下载安装服务脚本(systemd)..."
	Service_Server_Status_client
	echo -e "${Info} 正在写入客户端配置..."
	Read_config_client
	Modify_config_client
	echo -e "${Info} 正在配置 Iptables 防火墙..."
	Set_iptables
	echo -e "${Info} 正在添加 Iptables 规则..."
	Add_iptables_OUT "${server_port_s}"
	echo -e "${Info} 正在保存 Iptables 规则..."
	Save_iptables
	echo -e "${Info} 所有步骤执行完毕，正在启动客户端..."
	Start_ServerStatus_client
}

#更新
Update_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	[[ ! -z ${PID} ]] && systemctl stop status-server
	Download_Server_Status_server
	rm -rf /usr/lib/systemd/system/status-server.service
	Service_Server_Status_server
	Start_ServerStatus_server
}
Update_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	[[ ! -z ${PID} ]] && systemctl stop status-client
	if [[ ! -e "${client_file}/status-client.py" ]]; then
		if [[ ! -e "${file}/status-client.py" ]]; then
			echo -e "${Error} ServerStatus 客户端文件不存在！\n" && exit 1
		else
			client_text="$(cat "${file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
			rm -rf "${file}/status-client.py"
		fi
	else
		client_text="$(cat "${client_file}/status-client.py"|sed 's/\"//g;s/,//g;s/ //g')"
	fi
	server_s="$(echo -e "${client_text}"|grep "SERVER="|awk -F "=" '{print $2}')"
	server_port_s="$(echo -e "${client_text}"|grep "PORT="|awk -F "=" '{print $2}')"
	username_s="$(echo -e "${client_text}"|grep "USER="|awk -F "=" '{print $2}')"
	password_s="$(echo -e "${client_text}"|grep "PASSWORD="|awk -F "=" '{print $2}')"
	Download_Server_Status_client
	Read_config_client
	Modify_config_client
	rm -rf /usr/lib/systemd/system/status-client.service
	Service_Server_Status_client
	Start_ServerStatus_client
}

#操作
Start_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	if [[ ! -z ${PID} ]]; then
		echo -e "${Error} 服务端已运行，请检查！\n" && exit 1
	else
		Read_config_server
		ulimit -n 51200
		nohup ${server_file}/sergate --config=${server_json} --web-dir=${web_file} --port=${server_port} > ${server_log_file} 2>&1 &
		sleep 2s 
		check_pid_server
		if [[ ! -z ${PID} ]]; then
			echo -e "${Info} 服务端启动成功！"
		else
			echo -e "${Error} 服务端启动失败！"
		fi
	fi
}
Stop_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	if [[ -z ${PID} ]]; then
		echo -e "${Error} 服务端未运行，请检查！\n" && exit 1
	else
		kill -9 ${PID}
		sleep 2s
		check_pid_server
		if [[ -z ${PID} ]]; then
			echo -e "${Info} 服务端停止成功！"
		else
			echo -e "${Error} 服务端停止失败！"
		fi
	fi
}
Restart_ServerStatus_server(){
	check_installed_server_status
	check_pid_server
	if [[ -z ${PID} ]]; then
		Start_ServerStatus_server
	else
		Stop_ServerStatus_server
		Start_ServerStatus_server
	fi
}
Uninstall_ServerStatus_server(){
	check_installed_server_status
	echo -e "${Tip} 是否要卸载服务端？（若同时安装了客户端，则仅卸载服务端）[y/N]"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid_server
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config_server
		Del_iptables "${server_port}"
		Save_iptables
		if [[ -e "${client_file}/status-client.py" ]]; then
			rm -rf "${server_file}"
			rm -rf "${web_file}"
		else
			rm -rf "${file}"
		fi
		if [[ -e "/etc/init.d/caddy" ]]; then
			/etc/init.d/caddy stop
			wget -N --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/caddy_install.sh
			chmod +x caddy_install.sh
			bash caddy_install.sh uninstall
			rm -rf caddy_install.sh
		fi
		systemctl disable status-server
		rm -rf "/usr/lib/systemd/system/status-server.service"
		systemctl daemon-reload
		echo -e "${Info} ServerStatus 服务端卸载完成！\n"
	else
		echo -e "${Info} 已取消卸载...\n"
	fi
}
Start_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	if [[ ! -z ${PID} ]]; then
		echo -e "${Error} ServerStatus 已运行，请检查！\n" && exit 1
	else
		ulimit -n 51200
		nohup python ${client_file}/status-client.py > ${client_log_file} 2>&1 &
		sleep 2s 
		check_pid_client
		if [[ ! -z ${PID} ]]; then
			echo -e "${Info} 客户端启动成功！"
		else
			echo -e "${Error} 客户端启动失败！"
		fi
	fi
}
Stop_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	if [[ -z ${PID} ]]; then 
		echo -e "${Error} ServerStatus 未运行，请检查！\n" && exit 1
	else
		kill -9 ${PID}
		sleep 2s
		check_pid_client
		if [[ -z ${PID} ]]; then
			echo -e "${Info} 服务端停止成功！"
		else
			echo -e "${Error} 服务端停止失败！"
		fi
	fi
}
Restart_ServerStatus_client(){
	check_installed_client_status
	check_pid_client
	if [[ -z ${PID} ]]; then
		Start_ServerStatus_client
	else
		Stop_ServerStatus_client
		Start_ServerStatus_client
	fi
}
Uninstall_ServerStatus_client(){
	check_installed_client_status
	echo -e "${Tip} 是否要卸载客户端？（若同时安装了服务端，则仅卸载客户端）[y/N]"
	echo
	read -e -p "(默认: n):" unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_pid_client
		[[ ! -z $PID ]] && kill -9 ${PID}
		Read_config_client
		Del_iptables_OUT "${client_port}"
		Save_iptables
		if [[ -e "${server_file}/sergate" ]]; then
			rm -rf "${client_file}"
		else
			rm -rf "${file}"
		fi
		systemctl disable status-client
		rm -rf "/usr/lib/systemd/system/status-client.service"
		systemctl daemon-reload
		echo -e "${Info} ServerStatus 客户端卸载完成！\n"
	else
		echo -e "${Info} 已取消卸载...\n"
	fi
}
View_ServerStatus_client(){
	check_installed_client_status
	Read_config_client
	clear && echo "————————————————————" && echo
	echo -e "  ServerStatus 客户端配置信息: 
 
  服务端 \t: ${Green_font_prefix}${client_server}${Font_color_suffix}
  端口　 \t: ${Green_font_prefix}${client_port}${Font_color_suffix}
  用户名 \t: ${Green_font_prefix}${client_user}${Font_color_suffix}
  密码　 \t: ${Green_font_prefix}${client_password}${Font_color_suffix}
 
————————————————————"
}
View_client_Log(){
	[[ ! -e ${client_log_file} ]] && echo -e "${Error} 未找到日志文件！\n" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 结束日志查看" && echo -e "如需查看完整日志内容，请用 ${Red_font_prefix}cat ${client_log_file}${Font_color_suffix} 命令" && echo
	tail -f ${client_log_file}
}
View_server_Log(){
	[[ ! -e ${erver_log_file} ]] && echo -e "${Error} 未找到日志文件！\n" && exit 1
	echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 结束日志查看" && echo -e "如需查看完整日志内容，请用 ${Red_font_prefix}cat ${server_log_file}${Font_color_suffix} 命令" && echo
	tail -f ${server_log_file}
}
Add_iptables_OUT(){
	iptables_ADD_OUT_port=$1
	iptables -I OUTPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_ADD_OUT_port} -j ACCEPT
	iptables -I OUTPUT -m state --state NEW -m udp -p udp --dport ${iptables_ADD_OUT_port} -j ACCEPT
}
Del_iptables_OUT(){
	iptables_DEL_OUT_port=$1
	iptables -D OUTPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_DEL_OUT_port} -j ACCEPT
	iptables -D OUTPUT -m state --state NEW -m udp -p udp --dport ${iptables_DEL_OUT_port} -j ACCEPT
}
Add_iptables(){
	iptables_ADD_IN_port=$1
	iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_ADD_IN_port} -j ACCEPT
	iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${iptables_ADD_IN_port} -j ACCEPT
}
Del_iptables(){
	iptables_DEL_IN_port=$1
	iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport ${iptables_DEL_IN_port} -j ACCEPT
	iptables -D INPUT -m state --state NEW -m udp -p udp --dport ${iptables_DEL_IN_port} -j ACCEPT
}
Save_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
	else
		iptables-save > /etc/iptables.up.rules
	fi
}
Set_iptables(){
	if [[ ${release} == "centos" ]]; then
		service iptables save
		chkconfig --level 2345 iptables on
	else
		iptables-save > /etc/iptables.up.rules
		echo -e '#!/bin/bash\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
		chmod +x /etc/network/if-pre-up.d/iptables
	fi
}
Update_Shell(){
	sh_new_ver=$(wget --no-check-certificate -qO- -t1 -T3 "https://raw.githubusercontent.com/LilligantMatsuri/ServerStatus/master/script/status_systemd.sh"|grep 'sh_ver="'|awk -F "=" '{print $NF}'|sed 's/\"//g'|head -1) && sh_new_type="github"
	[[ -z ${sh_new_ver} ]] && echo -e "${Error} 无法连接 GitHub！\n" && exit 0
	if [[ -e "/usr/lib/systemd/system/status-client.service" ]]; then
		rm -rf /usr/lib/systemd/system/status-client.service
		Service_Server_Status_client
	fi
	if [[ -e "/usr/lib/systemd/system/status-server.service" ]]; then
		rm -rf /usr/lib/systemd/system/status-server.service
		Service_Server_Status_server
	fi
	wget -N --no-check-certificate "https://raw.githubusercontent.com/LilligantMatsuri/ServerStatus/master/script/status_systemd.sh" -O status.sh && chmod +x status.sh
	echo -e "${Info} 脚本已更新至最新版本 ${Red_font_prefix}[v${sh_new_ver}]${Font_color_suffix}！"
	echo -e "${Tip} 由于更新方式为覆盖当前运行的脚本，若产生报错信息，无视即可\n" && exit 0
}
menu_client(){
echo && echo -e "  ServerStatus 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
 -- Author: Toyo | Maintainer: Matsuri --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 客户端
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 客户端
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 客户端
 ————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 客户端
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 客户端
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 客户端
 ————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 客户端配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 客户端信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 客户端日志
 ————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切换 服务端菜单" && echo
if [[ -e "${client_file}/status-client.py" ]]; then
	check_pid_client
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 且 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	if [[ -e "${file}/status-client.py" ]]; then
		check_pid_client
		if [[ ! -z "${PID}" ]]; then
			echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 且 ${Green_font_prefix}已启动${Font_color_suffix}"
		else
			echo -e " 当前状态: 客户端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
		fi
	else
		echo -e " 当前状态: 客户端 ${Red_font_prefix}未安装${Font_color_suffix}"
	fi
fi
echo
read -e -p " 请输入选项的编号[0-10]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_ServerStatus_client
	;;
	2)
	Update_ServerStatus_client
	;;
	3)
	Uninstall_ServerStatus_client
	;;
	4)
	Start_ServerStatus_client
	;;
	5)
	Stop_ServerStatus_client
	;;
	6)
	Restart_ServerStatus_client
	;;
	7)
	Set_ServerStatus_client
	;;
	8)
	View_ServerStatus_client
	;;
	9)
	View_client_Log
	;;
	10)
	menu_server
	;;
	*)
	echo -e "${Error} 请输入有效的编号[0-10]！\n"
	;;
esac
}
menu_server(){
echo && echo -e "  ServerStatus 一键安装管理脚本 ${Red_font_prefix}[v${sh_ver}]${Font_color_suffix}
 -- Author: Toyo | Maintainer: Matsuri --
  
 ${Green_font_prefix} 0.${Font_color_suffix} 升级脚本
 ————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 安装 服务端
 ${Green_font_prefix} 2.${Font_color_suffix} 更新 服务端
 ${Green_font_prefix} 3.${Font_color_suffix} 卸载 服务端
 ————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 启动 服务端
 ${Green_font_prefix} 5.${Font_color_suffix} 停止 服务端
 ${Green_font_prefix} 6.${Font_color_suffix} 重启 服务端
 ————————————
 ${Green_font_prefix} 7.${Font_color_suffix} 设置 服务端配置
 ${Green_font_prefix} 8.${Font_color_suffix} 查看 服务端信息
 ${Green_font_prefix} 9.${Font_color_suffix} 查看 服务端日志
 ————————————
 ${Green_font_prefix}10.${Font_color_suffix} 切换 客户端菜单" && echo
if [[ -e "${server_file}/sergate" ]]; then
	check_pid_server
	if [[ ! -z "${PID}" ]]; then
		echo -e " 当前状态: 服务端 ${Green_font_prefix}已安装${Font_color_suffix} 且 ${Green_font_prefix}已启动${Font_color_suffix}"
	else
		echo -e " 当前状态: 服务端 ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
	fi
else
	echo -e " 当前状态: 服务端 ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入选项的编号[0-10]:" num
case "$num" in
	0)
	Update_Shell
	;;
	1)
	Install_ServerStatus_server
	;;
	2)
	Update_ServerStatus_server
	;;
	3)
	Uninstall_ServerStatus_server
	;;
	4)
	Start_ServerStatus_server
	;;
	5)
	Stop_ServerStatus_server
	;;
	6)
	Restart_ServerStatus_server
	;;
	7)
	Set_ServerStatus_server
	;;
	8)
	List_ServerStatus_server
	;;
	9)
	View_server_Log
	;;
	10)
	menu_client
	;;
	*)
	echo -e "${Error} 请输入有效的编号[0-10]！\n"
	;;
esac
}

check_sys
action=$1
if [[ ! -z $action ]]; then
	if [[ $action = "s" ]]; then
		menu_server
	elif [[ $action = "c" ]]; then
		menu_client
	fi
else
	menu_server
fi
