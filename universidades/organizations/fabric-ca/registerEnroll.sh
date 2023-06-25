#!/bin/bash

function createUniversity() {
  local NAME=$1  # Definir la variable NAME usando el primer argumento de la función
  local PORT=$2  # Definir la variable PORT usando el segundo argumento de la función

  infoln "Enrolling the CA admin"
  mkdir -p organizations/peerOrganizations/${NAME}.universidades.com/

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:${PORT} --caname ca-${NAME} --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null
 
  local cert_path="cacerts/localhost-${PORT}-ca-${NAME}.pem"

  echo $cert_path

  echo "NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: $cert_path 
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: "${cert_path}"
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: "${cert_path}"
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: "${cert_path}"
    OrganizationalUnitIdentifier: orderer" > "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/msp/config.yaml"
  infoln "Registering peer0"
  set -x
  fabric-ca-client register --caname ca-${NAME} --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering user"
  set -x
  fabric-ca-client register --caname ca-${NAME} --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the org admin"
  set -x
  fabric-ca-client register --caname ca-${NAME} --id.name ${NAME}admin --id.secret ${NAME}adminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the peer0 msp"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${PORT} --caname ca-${NAME} -M "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/msp" --csr.hosts peer0.${NAME}.universidades.com --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/msp/config.yaml"

  infoln "Generating the peer0-tls certificates"
  set -x
  fabric-ca-client enroll -u https://peer0:peer0pw@localhost:${PORT} --caname ca-${NAME} -M "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls" --enrollment.profile tls --csr.hosts peer0.${NAME}.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/ca.crt"
  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/signcerts/"* "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/server.crt"
  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/keystore/"* "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/server.key"

  mkdir -p "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/msp/tlscacerts/ca.crt"

  mkdir -p "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/tlsca"
  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/tlsca/tlsca.${NAME}.universidades.com-cert.pem"

  mkdir -p "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/ca"
  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/peers/peer0.${NAME}.universidades.com/msp/cacerts/"* "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/ca/ca.${NAME}.universidades.com-cert.pem"

  infoln "Generating the user msp"
  set -x
  fabric-ca-client enroll -u https://user1:user1pw@localhost:${PORT} --caname ca-${NAME} -M "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/users/User1@${NAME}.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/users/User1@${NAME}.universidades.com/msp/config.yaml"

  infoln "Generating the org admin msp"
  set -x
  fabric-ca-client enroll -u https://${NAME}admin:${NAME}adminpw@localhost:${PORT} --caname ca-${NAME} -M "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/users/Admin@${NAME}.universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/${NAME}/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/msp/config.yaml" "${PWD}/organizations/peerOrganizations/${NAME}.universidades.com/users/Admin@${NAME}.universidades.com/msp/config.yaml"
}



function createOrderer() {
  infoln "Enrolling the CA admin"
  mkdir -p organizations/ordererOrganizations/universidades.com

  export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/ordererOrganizations/universidades.com

  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  echo 'NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-orderer.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-orderer.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-orderer.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-7054-ca-orderer.pem
    OrganizationalUnitIdentifier: orderer' > "${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml"

  infoln "Registering orderer"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Registering the orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  infoln "Generating the orderer msp"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:7054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp" --csr.hosts orderer.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/config.yaml"

  infoln "Generating the orderer-tls certificates"
  set -x
  fabric-ca-client enroll -u https://orderer:ordererpw@localhost:7054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls" --enrollment.profile tls --csr.hosts orderer.universidades.com --csr.hosts localhost --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/ca.crt"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/signcerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.crt"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/keystore/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/server.key"

  mkdir -p "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem"

  mkdir -p "${PWD}/organizations/ordererOrganizations/universidades.com/msp/tlscacerts"
  cp "${PWD}/organizations/ordererOrganizations/universidades.com/orderers/orderer.universidades.com/tls/tlscacerts/"* "${PWD}/organizations/ordererOrganizations/universidades.com/msp/tlscacerts/tlsca.universidades.com-cert.pem"

  infoln "Generating the admin msp"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:7054 --caname ca-orderer -M "${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp" --tls.certfiles "${PWD}/organizations/fabric-ca/ordererOrg/tls-cert.pem"
  { set +x; } 2>/dev/null

  cp "${PWD}/organizations/ordererOrganizations/universidades.com/msp/config.yaml" "${PWD}/organizations/ordererOrganizations/universidades.com/users/Admin@universidades.com/msp/config.yaml"
}
