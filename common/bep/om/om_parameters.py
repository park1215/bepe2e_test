OM_JWT_URL="https://jwt.us-or.viasat.io/v1/token?stripe=bepapi-nonprod&name=preprod"
OM_NP_URL="https://preprod.om.bepapi-nonprod.viasat.io/"
#OM_SQS_NAME = "bepe2e-test-om"
OM_SNS_TOPIC ="arn:aws:sns:us-west-2:132986401742:bep-om-preprod-topic-events"
OM_FUTURE_ORDERS_BUCKET = {"ES":"future-orders-eu","NO":"future-orders-no","PL":"future-orders-pl"}

#SPB_NEEDS = {"RESIDENTIAL_INTERNET": [productTypeId, productInstanceId], "EQUIPMENT_LEASE_FEE":[productTypeId, productInstanceId], "ACTIVATION_FEE": [productTypeId, productInstanceId]}

PRODUCTS_50= [
    {
      "id": "bf01383b-69c5-49e7-8ff5-4723b629bef0",
      "name": "GBS Internet Connectivity",
      "description": "null",
      "kind": "Component",
      "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
      "products": [
        {
          "id": "97239bba-93ae-49f5-b629-bc833d111f67",
          "name": "Contract Terms",
          "description": "null",
          "kind": "Component",
          "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
          "products": [
            {
              "id": "c8eaf376-6933-401d-a39a-8638c55aa39c",
              "name": "24 Months",
              "description": "null",
              "kind": "Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            }
          ]
        },
        {
          "id": "6b69ef8b-f07e-46d8-9afd-2a3e3463f872",
          "name": "Internet Access",
          "description": "null",
          "kind": "Component",
          "characteristics": [
            {
              "name": "charName",
              "value": "ViaSat-1",
              "valueType": "string"
            }
          ],
          "products": [
            {
              "id": "61bc06e2-c0a0-4634-9368-edca0c57f98d",
              "name": "GBS Data Allowance",
              "description": "null",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "c37834b0-a68b-438e-91d1-9fcc86fd9b50",
              "name": "Bandwidth Down",
              "description": "null",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "3b618377-49aa-4045-9168-45d786d97efb",
              "name": "Video Shaping",
              "description": "null",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "1d775289-ce6d-4bd6-b358-5ec2bc43d0e8",
              "name": "10 EMail Addresses",
              "description": "null",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "3331c8a8-80e0-4905-99b6-dac0ea118fb5",
              "name": "Bandwidth Up",
              "description": "null",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "aeeb4914-be14-4aed-9416-69a2bcb1f85c",
              "name": "Priority Threshold",
              "description": "null",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "f11797eb-f185-4dce-9e49-0cdb14d7640f",
              "name": "Included IPs",
              "description": "null",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "b37f8efb-4dd7-4462-9d4e-e025f639af06",
              "name": "Internet Monthly Charge",
              "description": "null",
              "kind": "Recurring_Charge",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            }
          ]
        },
        {
          "id": "67c3ab6a-54e8-44ef-91a9-913337866df7",
          "name": "Legacy Catalog Mapping",
          "description": "null",
          "kind": "Customer_Facing_Service_Component",
          "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
          "products": [
            {
              "id": "ebad8ddd-6900-4934-8918-eee64dd1b966",
              "name": "Legacy Equipment MCR RFS",
              "description": "null",
              "kind": "Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            },
            {
              "id": "389ed5e8-0ade-485e-bef3-d880cbda04dd",
              "name": "Legacy Install MCR RFS",
              "description": "null",
              "kind": "Component",
              "characteristics": [
                {
                  "name": "charName",
                  "value": "null",
                  "valueType": "undefined"
                },
                {
                  "name": "charName",
                  "value": "null",
                  "valueType": "undefined"
                }
              ],
            },
            {
              "id": "d277dd01-09f0-44d3-b1a5-de6b494abd00",
              "name": "Legacy MCR RFS",
              "description": "null",
              "kind": "Component",
              "characteristics": [
                {
                  "name": "charName",
                  "value": "null",
                  "valueType": "undefined"
                }
              ],
            }
          ]
        },
        {
          "id": "ac94b7aa-0384-4185-908d-6b3c9918a99c",
          "name": "Internet Add Ons",
          "description": "null",
          "kind": "Component",
          "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
        },
        {
          "id": "e7bd3035-8e0a-45dc-9922-2ce0cbff3f0a",
          "name": "Equipment",
          "description": "null",
          "kind": "Component",
          "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
          "products": [
            {
              "id": "7a5ae5df-8d88-47c7-b846-4c4c06f3def5",
              "name": "VS2 Data Modem",
              "description": "null",
              "kind": "Component",
              "characteristics": [{'name': 'charName', 'value': 'null', 'valueType': 'undefined'}],
            }
          ]
        }
      ]
    }
  ]

PRODUCTS_50_PRICES= [
    {
      "id": "bf01383b-69c5-49e7-8ff5-4723b629bef0",
      "name": "GBS Internet Connectivity",
      "description": "",
      "kind": "Component",
      "characteristics": [],
      "prices": [],
      "products": [
        {
          "id": "97239bba-93ae-49f5-b629-bc833d111f67",
          "name": "Contract Terms",
          "description": "",
          "kind": "Component",
          "characteristics": [],
          "prices": [],
          "products": [
            {
              "id": "c8eaf376-6933-401d-a39a-8638c55aa39c",
              "name": "24 Months",
              "description": "",
              "kind": "Component",
              "characteristics": [],
              "prices": []
            }
          ]
        },
        {
          "id": "6b69ef8b-f07e-46d8-9afd-2a3e3463f872",
          "name": "Internet Access",
          "description": "",
          "kind": "Component",
          "characteristics": [
            {
              "name": "charName",
              "value": "ViaSat-1",
              "valueType": "string"
            }
          ],
          "prices": [],
          "products": [
            {
              "id": "61bc06e2-c0a0-4634-9368-edca0c57f98d",
              "name": "GBS Data Allowance",
              "description": "",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "c37834b0-a68b-438e-91d1-9fcc86fd9b50",
              "name": "Bandwidth Down",
              "description": "",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "3b618377-49aa-4045-9168-45d786d97efb",
              "name": "Video Shaping",
              "description": "",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "1d775289-ce6d-4bd6-b358-5ec2bc43d0e8",
              "name": "10 EMail Addresses",
              "description": "",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "3331c8a8-80e0-4905-99b6-dac0ea118fb5",
              "name": "Bandwidth Up",
              "description": "",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "aeeb4914-be14-4aed-9416-69a2bcb1f85c",
              "name": "Priority Threshold",
              "description": "",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "f11797eb-f185-4dce-9e49-0cdb14d7640f",
              "name": "Included IPs",
              "description": "",
              "kind": "Customer_Facing_Service_Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "b37f8efb-4dd7-4462-9d4e-e025f639af06",
              "name": "Internet Monthly Charge",
              "description": "",
              "kind": "Recurring_Charge",
              "characteristics": [],
              "prices": [
                {
                  "amount": {
                    "currency": {
                      "name": "USD",
                      "alphabeticCode": "USD",
                      "numericCode": 0,
                      "majorUnitSymbol": ""
                    },
                    "value": 140
                  },
                  "description": "null",
                  "name": "Internet Monthly Charge",
                  "percentage": "null",
                  "kind": "GBS_I_Recurring_Rate",
                  "recurrence": "Monthly",
                  "unitOfMeasure": "Each"
                }
              ]
            }
          ]
        },
        {
          "id": "67c3ab6a-54e8-44ef-91a9-913337866df7",
          "name": "Legacy Catalog Mapping",
          "description": "",
          "kind": "Customer_Facing_Service_Component",
          "characteristics": [],
          "prices": [],
          "products": [
            {
              "id": "ebad8ddd-6900-4934-8918-eee64dd1b966",
              "name": "Legacy Equipment MCR RFS",
              "description": "",
              "kind": "Component",
              "characteristics": [],
              "prices": []
            },
            {
              "id": "389ed5e8-0ade-485e-bef3-d880cbda04dd",
              "name": "Legacy Install MCR RFS",
              "description": "",
              "kind": "Component",
              "characteristics": [
                {
                  "name": "charName",
                  "value": "null",
                  "valueType": "undefined"
                },
                {
                  "name": "charName",
                  "value": "null",
                  "valueType": "undefined"
                }
              ],
              "prices": []
            },
            {
              "id": "d277dd01-09f0-44d3-b1a5-de6b494abd00",
              "name": "Legacy MCR RFS",
              "description": "",
              "kind": "Component",
              "characteristics": [
                {
                  "name": "charName",
                  "value": "null",
                  "valueType": "undefined"
                }
              ],
              "prices": []
            }
          ]
        },
        {
          "id": "ac94b7aa-0384-4185-908d-6b3c9918a99c",
          "name": "Internet Add Ons",
          "description": "",
          "kind": "Component",
          "characteristics": [],
          "prices": [],
          "products": []
        },
        {
          "id": "e7bd3035-8e0a-45dc-9922-2ce0cbff3f0a",
          "name": "Equipment",
          "description": "",
          "kind": "Component",
          "characteristics": [],
          "prices": [],
          "products": [
            {
              "id": "7a5ae5df-8d88-47c7-b846-4c4c06f3def5",
              "name": "VS2 Data Modem",
              "description": "",
              "kind": "Component",
              "characteristics": [],
              "prices": []
            }
          ]
        }
      ]
    }
  ]

PRODUCTS_12= \
    [{
        "id": "abb6b0ca-9d9d-4862-91e5-eff035ab3baa",
        "name": "Residential Internet Connectivity",
        "description": "",
        "kind": "Component",
        "characteristics": [],
        "products": [
        {
            "id": "83f0f024-1d8b-470f-8a5d-c4727a8df7cf",
            "name": "Residential Provisioning",
            "description": "",
            "kind": "Component",
            "characteristics": [],
            "products": [
                {
                  "id": "95ecc7e9-da60-4546-b353-0045b1ff8f09",
                  "name": "Residential 12G -50 -3 -720p",
                  "description": "",
                  "kind": "Customer_Facing_Service_Component",
                  "characteristics": [],
                },
                {
                  "id": "7e57ccf2-64a8-4e6a-9793-876c7845ef69",
                  "name": "Residential Monthly Fee Recurring",
                  "description": "",    
                  "kind": "Recurring_Charge",       
                  "characteristics": [],
                }
            ]
        },
        {
            "id": "d45c7d89-9ffb-4e01-a23d-40add324124d",
            "name": "Residential Contract",
            "description": "",
            "kind": "Component",
            "characteristics": [
            {
                "name": "charName",
                "value":"null",
                "valueType": "undefined"
            }
            ],
            "products": [
            {
                "id": "ff3943f8-d9e1-4b9d-b677-6931ed303eb6",
                "name": "Residential 24 Mo Contract CFS",
                "description": "",
                "kind": "Customer_Facing_Service_Component",
                "characteristics": [
                  {
                    "name": "charName",
                    "value":"null",
                    "valueType": "undefined"
                  }
                ]
            }
            ]
        },
        {
            "id": "7d642f9d-6009-4df1-9506-abee3fe69713",
            "name": "Residential Equipment",
            "description": "",
            "kind": "Component",
            "characteristics": [
                {
                    "name": "charName",
                    "value":"null",
                    "valueType": "undefined"
                }
            ],
            "products": [
                {
                    "id": "60e5863d-8b83-446b-a94e-1f755a897f92",
                    "name": "Residential Equipment PRS",
                    "description": "",
                    "kind": "Component",
                    "characteristics": []
                }
            ]
        },
        {
            "id": "31dd5235-aa70-4445-8c52-a216c2f1599b",
            "name": "Residential Lease",
            "description": "",
            "kind": "Component",
            "characteristics": [
            {
                "name": "charName",
                "value":"null",
                "valueType": "undefined"
            }
            ],
            "products": [
                {
                    "id": "c26dd791-ad78-46e7-9d49-35062cfd96e1",
                    "name": "Residential Monthly Lease Fee CFS",
                    "description": "",
                    "kind": "Customer_Facing_Service_Component",
                    "characteristics": [
                        {
                            "name": "charName",
                            "value":"null",
                            "valueType": "undefined"
                        }
                    ]
                }
            ]
        },
        {
            "id": "475789c5-f580-4e33-a062-308cae7f8344",
            "name": "Residential Field Services",
            "description": "",
            "kind": "Component",
            "characteristics": [
            {
                "name": "charName",
                "value":"null",
                "valueType": "undefined"
            }
            ],
            "products": [
                {
                    "id": "aa340708-fda4-464a-a9cc-efebd710c4e7",
                    "name": "Residential Pro Install CFS",
                    "description": "",
                    "kind": "Customer_Facing_Service_Component",
                    "characteristics": [
                        {
                            "name": "charName",
                            "value":"null",
                            "valueType": "undefined"
                        }
                    ]
                }
            ]
        }
        ]
    }]
'''
PRODUCTS= \
    [{
        "id": "abb6b0ca-9d9d-4862-91e5-eff035ab3baa",
        "name": "Residential Internet Connectivity",
        "description": "",
        "kind": "Component",
        "characteristics": [],
        "prices": [],
        "products": [
        {
            "id": "83f0f024-1d8b-470f-8a5d-c4727a8df7cf",
            "name": "Residential Provisioning",
            "description": "",
            "kind": "Component",
            "characteristics": [],
            "prices": [],
            "products": [
                {
                  "id": "95ecc7e9-da60-4546-b353-0045b1ff8f09",
                  "name": "Residential 12G -50 -3 -720p",
                  "description": "",
                  "kind": "Customer_Facing_Service_Component",
                  "characteristics": [],
                  "prices": []
                },
                {
                  "id": "7e57ccf2-64a8-4e6a-9793-876c7845ef69",
                  "name": "Residential Monthly Fee Recurring",
                  "description": "",    
                  "kind": "Recurring_Charge",       
                  "characteristics": [],
                  "prices": [
                    {
                      "amount": {
                        "currency": {
                          "name": "MXN",
                          "alphabeticCode": "MXN",
                          "numericCode": 0,
                          "majorUnitSymbol": ""
                        },
                        "value": 1260
                      },
                      "description": "This charge is for the product offer monthly recurring fee",
                      "kind": "Multi_VNO_Recurring_Rate",
                      "name": "Residential Monthly Fee Recurring",
                      "percentage":"null",
                      "unitOfMeasure": "Each",
                      "recurrence": "Monthly"
                    }
                    ]
                }
            ]
        },
        {
            "id": "d45c7d89-9ffb-4e01-a23d-40add324124d",
            "name": "Residential Contract",
            "description": "",
            "kind": "Component",
            "characteristics": [
            {
                "name": "charName",
                "value":"null",
                "valueType": "undefined"
            }
            ],
            "prices": [],
            "products": [
            {
                "id": "ff3943f8-d9e1-4b9d-b677-6931ed303eb6",
                "name": "Residential 24 Mo Contract CFS",
                "description": "",
                "kind": "Customer_Facing_Service_Component",
                "characteristics": [
                  {
                    "name": "charName",
                    "value":"null",
                    "valueType": "undefined"
                  }
                ],
                "prices": []
            }
            ]
        },
        {
            "id": "7d642f9d-6009-4df1-9506-abee3fe69713",
            "name": "Residential Equipment",
            "description": "",
            "kind": "Component",
            "characteristics": [
                {
                    "name": "charName",
                    "value":"null",
                    "valueType": "undefined"
                }
            ],
            "prices": [],
            "products": [
                {
                    "id": "60e5863d-8b83-446b-a94e-1f755a897f92",
                    "name": "Residential Equipment PRS",
                    "description": "",
                    "kind": "Component",
                    "characteristics": [],
                    "prices": []
                }
            ]
        },
        {
            "id": "31dd5235-aa70-4445-8c52-a216c2f1599b",
            "name": "Residential Lease",
            "description": "",
            "kind": "Component",
            "characteristics": [
            {
                "name": "charName",
                "value":"null",
                "valueType": "undefined"
            }
            ],
            "prices": [],
            "products": [
                {
                    "id": "c26dd791-ad78-46e7-9d49-35062cfd96e1",
                    "name": "Residential Monthly Lease Fee CFS",
                    "description": "",
                    "kind": "Customer_Facing_Service_Component",
                    "characteristics": [
                        {
                            "name": "charName",
                            "value":"null",
                            "valueType": "undefined"
                        }
                    ],
                    "prices": []
                }
            ]
        },
        {
            "id": "475789c5-f580-4e33-a062-308cae7f8344",
            "name": "Residential Field Services",
            "description": "",
            "kind": "Component",
            "characteristics": [
            {
                "name": "charName",
                "value":"null",
                "valueType": "undefined"
            }
            ],
            "prices": [],
            "products": [
                {
                    "id": "aa340708-fda4-464a-a9cc-efebd710c4e7",
                    "name": "Residential Pro Install CFS",
                    "description": "",
                    "kind": "Customer_Facing_Service_Component",
                    "characteristics": [
                        {
                            "name": "charName",
                            "value":"null",
                            "valueType": "undefined"
                        }
                    ],
                    "prices": []
                }
            ]
        }
        ]
    }]
'''

CHARACTERISTICS={ "Viasat Business Metered 50 GB":[ \
                { \
                  "name": "charName", \
                  "value": "null", \
                  "valueType": "undefined" \
                }]}

CHARACTERISTICS_LONG={ "Viasat 12 Mbps":[ \
                { \
                  "name": "DOWNLOAD_SPEED", \
                  "value": "Download Speeds up to 12.0 Mbps", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "UPLOAD_SPEED", \
                  "value": "Upload Speeds up to 3.0 Mbps", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "DATA_CAP_GB", \
                  "value": "50", \
                  "valueType": "float" \
                }, \
                { \
                  "name": "DOWNLOAD_RATE", \
                  "value": "12", \
                  "valueType": "float" \
                }, \
                { \
                  "name": "DOWNLOAD_RATE_UNIT", \
                  "value": "Mbps", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "UPLOAD_RATE", \
                  "value": "3", \
                  "valueType": "float" \
                }, \
                { \
                  "name": "UPLOAD_RATE_UNIT", \
                  "value": "Mbps", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "UNMETERED_PERIOD_START", \
                  "value": "02:00", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "UNMETERED_PERIOD_END", \
                  "value": "07:00", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "CONTRACT_DESCRIPTION", \
                  "value": "2-Year Contract Required", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "WIRELESS_ROUTER", \
                  "value": "Wireless router (3x3 MU-MIMO, 802.11 a/b/g/n/ac, simultaneous dual-band) and 2-port gigabit Ethernet router included", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "VIDEO_OPTIMIZATION", \
                  "value": "Streaming video at HD quality (typically 720p). The Video Data Extender saves your data by streaming video at DVD quality, optimized for 480p. ", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "FEES", \
                  "value": "Monthly equipment lease fee and taxes may apply.", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "PRICE", \
                  "value": "1260 (Pesos)/month", \
                  "valueType": "string" \
                }, \
                { \
                  "name": "DATA_ALLOWANCE_POLICY", \
                  "value": "After 50 GB of data usage, only Web and Email until Buy More", \
                  "valueType": "string" \
                } \
              ]}
