
#######################################
###### ELIMINACIÓN INSTALACIONES ######
#######         PREVIAS          ######
#######################################

cd 
sudo rm -rf fabric-universidades-iebs
#Reinicio de contenedores
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker volume prune
docker network prune

sudo apt-get purge docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo rm -rf /var/lib/docker/volumes
sudo rm -rf /etc/default/docker
sudo rm -rf /etc/sysconfig/docker
sudo rm /usr/local/bin/docker-compose


#######################################
########## REQUISITOS PREVIOS #########
#######################################

#Comprobación de versiones
git version
curl version

#Descarga archivos docker
curl -fsSL https://get.docker.com -o get-docker.sh

#Instalación de docker
sudo sh get-docker.sh
docker version 

#Instalación de docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose version

#Instalación de Go 
sudo apt install golang-go

#Instalación de Node.js
sudo apt install npm

#Instalación de jq - para archivos json 
sudo apt install jq

#Definición de privilegios de usuario - reiniciar consola para hacerlo efectivo
sudo usermod -aG sudo $USER
sudo usermod -aG docker $USER

#Clonación de repositorio
git clone https://github.com/ddrcdev/fabric-universidades-iebs

#Privilegios en la carpeta /bin
sudo chmod -R +x fabric-universidades-iebs

#Instalación en repositorio github
cd fabric-universidades-iebs/universidades


#######################################
###### ELIMINAR CONFIG. PREVIAS #######
#######################################

#Reinicio de contenedores
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker volume prune
docker network prune

#Eliminar acreditaciones generadas
sudo rm -rf organizations/peerOrganizations
sudo rm -rf organizations/ordererOrganizations
sudo rm -rf organizations/fabric-ca/madrid/
sudo rm -rf organizations/fabric-ca/bogota/
sudo rm -rf organizations/fabric-ca/ordererOrg/
rm -rf channel-artifacts/

#Creación de carpeta para generación de nuevas acreditaciones
mkdir channel-artifacts
#Privilegios en la carpeta /fabric-ca
sudo chmod -R +x channel-artifacts


#Levantamos clienta CA de nodos
docker-compose -f docker/docker-compose-ca.yaml up -d

#Privilegios en la carpeta /fabric-ca
sudo chmod -R +x organizations/fabric-ca


########################################
###### GENERACIÓN DE CREDENCIALES ######
########################################

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config
. ./organizations/fabric-ca/registerEnroll.sh && createUniversity "madrid" "8054"
. ./organizations/fabric-ca/registerEnroll.sh && createUniversity "bogota" "9054"
. ./organizations/fabric-ca/registerEnroll.sh && createOrderer 

sudo chmod -R +x organizations/peerOrganizations
sudo chmod -R +x organizations/ordererOrganizations
sudo chmod -R +x organizations/fabric-ca

#Despliegue de red con canales 1 y 2 
docker-compose -f docker/docker-compose-universidades.yaml up -d

#######################################
##### CANAL: universidadeschannel #####
#######################################

export FABRIC_CFG_PATH=${PWD}/configtx
configtxgen -profile UniversidadesGenesis -outputBlock ./channel-artifacts/universidadeschannel.block -channelID universidadeschannel

export FABRIC_CFG_PATH=${PWD}/../config
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key
osnadmin channel join --channelID universidadeschannel --config-block ./channel-artifacts/universidadeschannel.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
osnadmin channel list -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"

#Adición de nodo - Univ.Madrid
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=${PWD}/../config
export PEER0_MADRID_CA=${PWD}/organizations/peerOrganizations/madrid.universidades.com/peers/peer0.madrid.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="MadridMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_MADRID_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/madrid.universidades.com/users/Admin@madrid.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:7051
peer channel join -b ./channel-artifacts/universidadeschannel.block

#Adición de nodo - Univ.Bogota
export PEER0_BOGOTA_CA=${PWD}/organizations/peerOrganizations/bogota.universidades.com/peers/peer0.bogota.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="BogotaMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BOGOTA_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/bogota.universidades.com/users/Admin@bogota.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:9051
peer channel join -b ./channel-artifacts/universidadeschannel.block

#######################################
####### AÑADIR NODO UNIV.BERLIN #######
#######################################

#Generación certificados Univ.Berlin (tercer nodo)
#Levantamos clienta CA de berlin
docker-compose -f docker/docker-compose-berlin-ca.yaml up -d

#Configuración nodo Univ.Berlin
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../config
. ./organizations/fabric-ca/registerEnroll.sh && createUniversity "berlin" "2054"

#Configuración nodo Univ.Berlin
cd berlin/

#Importamos config en formato json
export FABRIC_CFG_PATH=$PWD
../../bin/configtxgen -printOrg BerlinMSP > ../organizations/peerOrganizations/berlin.universidades.com/berlin.json
sudo chmod -R +x organizations

#Levantamos nodo Univ.Berlin
cd ..
docker-compose -f docker/docker-compose-berlin.yaml up -d

#Unión de Univ.Berlin a canal universidadeschannel
export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=${PWD}/../config
export PEER0_BERLIN_CA=${PWD}/organizations/peerOrganizations/berlin.universidades.com/peers/peer0.berlin.universidades.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="BerlinMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_BERLIN_CA
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/berlin.universidades.com/users/Admin@berlin.universidades.com/msp
export CORE_PEER_ADDRESS=localhost:2051
peer channel join -b channel-artifacts/universidadeschannel.block
