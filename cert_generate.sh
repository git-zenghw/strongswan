#!/bin/sh

serverCN="vpn.server"
serverIP="192.168.1.200"
clientCN="vpn.client"

dn="C=CA, O=zenghw, CN="
ca_dn="${dn}zenghw CA"
server_dn="${dn}${serverCN}"
client_dn="${dn}${clientCN}"

days=3650

ipsec_d="/etc/ipsec.d"
caKeyfile="${ipsec_d}/private/caKey.pem"
caCertfile="${ipsec_d}/cacerts/caCert.pem"

serverKeyfile="${ipsec_d}/private/serverKey.pem"
serverPubKeyfile="${ipsec_d}/certs/serverPubKey.pem"
serverCertfile="${ipsec_d}/certs/serverCert.pem"

client_dir=/root/client
if [ ! -d $client_dir ]
then
mkdir -p $client_dir
fi

clientKeyfile="${client_dir}/clientKey.pem"
clientPubKeyfile="${client_dir}/clientPubKey.pem"
clientCertfile="${client_dir}/clientCert.pem"


#生成CA证书:
#生成一个私钥
ipsec pki --gen --type rsa --size 4096 --outform pem > ${caKeyfile}
#使用私钥生成自签名根证书
ipsec pki --self --ca --lifetime ${days} --in ${caKeyfile} --type rsa --dn "${ca_dn}" --outform pem > ${caCertfile}

## 显示CA证书内容
ipsec pki --print --in ${caCertfile}

cp -r $caCertfile $client_dir
cp -r $caKeyfile $client_dir


#生成服务端证书:

#生成一个私钥
ipsec pki --gen --type rsa --size 2048 --outform pem > ${serverKeyfile}

#用私钥生成公钥
ipsec pki --pub --in ${serverKeyfile} --type rsa --outform pem > ${serverPubKeyfile}

#用根证书给公钥签名生成服务器证书
ipsec pki --issue --lifetime ${days} --cacert ${caCertfile} --cakey ${caKeyfile} --in ${serverPubKeyfile} --dn "${server_dn}" --san="${serverCN}" --san="${serverIP}" --flag serverAuth --flag ikeIntermediate --outform pem > ${serverCertfile}

## 显示服务器证书内容
ipsec pki --print --in ${serverCertfile}


#生成客户端证书:

#生成一个私钥
ipsec pki --gen --type rsa --size 2048 --outform pem > ${clientKeyfile}

#用私钥生成公钥
ipsec pki --pub --in ${clientKeyfile} --type rsa --outform pem > ${clientPubKeyfile}

#用根证书给公钥签名生成服务器证书
ipsec pki --issue --lifetime ${days} --cacert ${caCertfile} --cakey ${caKeyfile} --in ${clientPubKeyfile} --dn "${client_dn}" --san ${clientCN}  --flag clientAuth --outform pem > ${clientCertfile}

ipsec pki --print --in ${clientCertfile}


## 变更证书权限
# chmod -R 0600 "${ipsec_d}/private/"
