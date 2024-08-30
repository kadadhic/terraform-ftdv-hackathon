#! /usr/bin/python3

import json
import os
import time

import fmcapi
import requests

addr=os.environ.get('ADDR')
is_cdfmc = os.environ.get('IS_CDFMC')
token = os.environ.get('ACCESS_TOKEN')
domainUUID = os.environ.get('DOMAIN_UUID')
username=os.environ.get('FMC_USERNAME')
password=os.environ.get('FMC_PASSWORD')


def main():
    print("IN main-aws")

    with fmcapi.FMC(host=addr, username=username, password=password, autodeploy=False) as fmc:
        namer = "extended_net_acl"
        ext_acl = fmcapi.ExtendedAccessList(fmc=fmc)
        ext_acl.name = namer
        ext_acl.entries = []

        ace = fmcapi.ExtendedAccessListAce()
        ace.action = "DENY"
        ace.destinationNetworksLiterals = [
            {
                "type": "Network",
                "value": "10.0.10.0/24"
            }
        ]

        ace.sourceNetworksLiterals = [
            {
                "type": "Network",
                "value": "10.0.10.0/24"
            }
        ]

        ace.destinationPortsLiterals = [
            {
                "type": "PortLiteral",
                "port": "443",
                "protocol": "6"  # CHANGE TO TCP(6) or UDP(17)
            }
        ]

        ace.sourcePortsLiterals = [
            {
                "type": "PortLiteral",
                "port": "80",
                "protocol": "6"
            }
        ]

        ext_acl.entries.append(ace.build_ace())
        print("------------- Post Extended Access List ---------------")
        ext_acl.post()
        global acl
        acl = ext_acl.get()

        print("------------- Extended Access List ID ---------------")
        print(acl['id'])


def unknown():
    host = addr
    if is_cdfmc == "true":
        headers = {
            'accept': 'application/json',
            'Authorization': 'Bearer ' + token,
            'Content-Type': 'application/json'
        }
    else:
        username = os.environ.get('FMC_USERNAME')
        password = os.environ.get('FMC_PASSWORD')
        device_name = "FTD-1"
        print(host)
        print(username)
        print(password)
        print(device_name)

        # DomainUUID and Token
        domainurl = "https://"+host+"//api/fmc_platform/v1/auth/generatetoken"
        payload0={}

        domainresponse = requests.request("POST", domainurl,data=payload0, auth=(username ,password), verify=False)

        token1 = domainresponse.headers['X-auth-access-token']
        domainUUID = domainresponse.headers['DOMAIN_UUID']


        #####Defining Headers

        headers = {
            'accept': 'application/json',
            'X-auth-access-token': token1,
            'Content-Type': 'application/json'
        }


    # Base url

    baseurl = "https://"+host+"/api/fmc_config/v1/domain/"+domainUUID+"/devices/devicerecords"

    #####Device ID-1
    deviceurl1 = baseurl+"?filter=name:"+device_name
    devicepayload1={}
    deviceresponse1 = requests.request("GET", deviceurl1, headers=headers, data=devicepayload1, verify=False)
    json_data1 = json.loads(deviceresponse1.text)
    deviceID1 = json_data1["items"][0]["id"]
    print("----------------------Printing deviceID--------------------------")
    print(deviceID1)
    # deviceID1 = "36f9efb4-596d-11ef-8215-e7af50394a42"

    #####Physical Interface ID
    phyurl = baseurl + "/" + deviceID1 + "/physicalinterfaces?offset=1&limit=25"
    phypayload={}
    phyresponse = requests.request("GET", phyurl, headers=headers, data=phypayload, verify=False)
    json_phyinter = json.loads(phyresponse.text)
    phyID1 = json_phyinter["items"][0]["id"]
    phyID2 = json_phyinter["items"][1]["id"]
    phyID3 = json_phyinter["items"][2]["id"]
    print("----------------------Printing phyID--------------------------")
    print(phyID1)
    print(phyID2)
    print(phyID3)

    #####PBR
    pbrurl = baseurl + "/" + deviceID1 + "/policybasedroutes" ## CHANGE TO PBR
    payload = json.dumps({
        "ingressInterfaces": [
            {
                ### Inside Interface ###
                "id": f"{phyID3}"
            }
        ],
        "name": "PBR-req-test",
        "forwardingActions": [{
            "forwardingActionType": "SET_EGRESS_INTF_BY_ORDER",
            "matchCriteria": {
                "id": f"{acl['id']}"
            },
            "defaultInterface": True,
            "egressInterfaces": [
                {
                    ### Outside Interface ###
                    "id": f"{phyID1}"
                },
                {
                    ### Outside2 Interface ###
                    "id": f"{phyID2}"
                }
            ]}
        ]
    })
    pbrresponse = requests.request("POST", pbrurl, headers=headers, data=payload, verify=False)
    json_pbr = json.loads(pbrresponse.text)

    print("----------------------Printing PBR ID--------------------------")
    print(json_pbr['id'])

    # GET_Deployable devices
    getdeviceurl = "https://"+host+"/api/fmc_config/v1/domain/"+domainUUID+"/deployment/deployabledevices"
    getdevicepayload={}
    getdeviceresponse = requests.request("GET", getdeviceurl, headers=headers, data=getdevicepayload, verify=False)
    print(getdeviceresponse.text)
    print("Version---")
    json_version = json.loads(getdeviceresponse.text)
    version = json_version["items"][0]["version"]
    print(version)



    ##############
    ### REMOVE THIS EXIT() HERE TO DEPLOY
    ##############



    exit()
    # Deploying Devices
    deployurl = "https://"+host+"/api/fmc_config/v1/domain/"+domainUUID+"/deployment/deploymentrequests"
    deploypayload = json.dumps({
      "type": "DeploymentRequest",
      "version": version,
      "forceDeploy": False,
      "ignoreWarning": True,
      "deviceList": [
        deviceID1
      ],
      "deploymentNote": "--Deployed using RestAPI--"
    })

    deployresponse = requests.request("POST", deployurl, headers=headers, data=deploypayload, verify=False)
    print(deployresponse.text)


if __name__ == "__main__":
    main()
    unknown()