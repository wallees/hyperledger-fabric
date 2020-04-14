# Updating a Channel Configuration

채널에 속한 org가 누구인지, 채널 access 정책 또는 블록 배치사이즈 등 채널에 대한 모든 구성 정보를 말한다.  
**이 정보들은 원장에 블록(config 블록이라고 말함) 형태로 저장** 되기 떄문에, 첫번쨰로 만들어진 블록인 'genesis block'에는 채널의 부트스트랩에 필요한 초기 구성 내용이 들어있고 가장 최근에 만들어진 블록에는 가장 최신의 채널 구성 정보가 들어있게 된다. 

그렇기 때문에 구성 업데이트 과정은 일반적인 트랜잭션과 다르게 동작하며, 블록을 읽기 쉬운(human can read) 형태로 변경하고 이를 이용하여 값을 수정한 후에 다시 블록 형태로 변경시키는 작업을 진행한다.

<br>

> 소스를 직접 확인하고자 하면 [이곳](#source)을 참조한다.
 
<br>

## Editing a Config

<details>
<summary>JSON 형태로 변환한 config 내용</summary>
<div markdown="1">

```json
{
"channel_group": {
  "groups": {
    "Application": {
      "groups": {
        "Org1MSP": {
          "mod_policy": "Admins",
          "policies": {
            "Admins": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org1MSP",
                        "role": "ADMIN"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Readers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org1MSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Writers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org1MSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            }
          },
          "values": {
            "AnchorPeers": {
              "mod_policy": "Admins",
              "value": {
                "anchor_peers": [
                  {
                    "host": "peer0.org1.example.com",
                    "port": 7051
                  }
                ]
              },
              "version": "0"
            },
            "MSP": {
              "mod_policy": "Admins",
              "value": {
                "config": {
                  "admins": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNHRENDQWIrZ0F3SUJBZ0lRSWlyVmg3NVcwWmh0UjEzdmltdmliakFLQmdncWhrak9QUVFEQWpCek1Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RVpNQmNHQTFVRUNoTVFiM0puTVM1bGVHRnRjR3hsTG1OdmJURWNNQm9HQTFVRUF4TVRZMkV1CmIzSm5NUzVsZUdGdGNHeGxMbU52YlRBZUZ3MHhOekV4TWpreE9USTBNRFphRncweU56RXhNamN4T1RJME1EWmEKTUZzeEN6QUpCZ05WQkFZVEFsVlRNUk13RVFZRFZRUUlFd3BEWVd4cFptOXlibWxoTVJZd0ZBWURWUVFIRXcxVApZVzRnUm5KaGJtTnBjMk52TVI4d0hRWURWUVFEREJaQlpHMXBia0J2Y21jeExtVjRZVzF3YkdVdVkyOXRNRmt3CkV3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFNkdVeDlpczZ0aG1ZRE9tMmVHSlA5eW1yaXJYWE1Cd0oKQmVWb1Vpak5haUdsWE03N2NsSE5aZjArMGFjK2djRU5lMzQweGExZVFnb2Q0YjVFcmQrNmtxTk5NRXN3RGdZRApWUjBQQVFIL0JBUURBZ2VBTUF3R0ExVWRFd0VCL3dRQ01BQXdLd1lEVlIwakJDUXdJb0FnWWdoR2xCMjBGWmZCCllQemdYT280czdkU1k1V3NKSkRZbGszTDJvOXZzQ013Q2dZSUtvWkl6ajBFQXdJRFJ3QXdSQUlnYmlEWDVTMlIKRTBNWGRobDZFbmpVNm1lTEJ0eXNMR2ZpZXZWTlNmWW1UQVVDSUdVbnROangrVXZEYkZPRHZFcFRVTm5MUHp0Qwp5ZlBnOEhMdWpMaXVpaWFaCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                  ],
                  "crypto_config": {
                    "identity_identifier_hash_function": "SHA256",
                    "signature_hash_family": "SHA2"
                  },
                  "name": "Org1MSP",
                  "root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNRekNDQWVxZ0F3SUJBZ0lSQU03ZVdTaVM4V3VVM2haMU9tR255eXd3Q2dZSUtvWkl6ajBFQXdJd2N6RUwKTUFrR0ExVUVCaE1DVlZNeEV6QVJCZ05WQkFnVENrTmhiR2xtYjNKdWFXRXhGakFVQmdOVkJBY1REVk5oYmlCRwpjbUZ1WTJselkyOHhHVEFYQmdOVkJBb1RFRzl5WnpFdVpYaGhiWEJzWlM1amIyMHhIREFhQmdOVkJBTVRFMk5oCkxtOXlaekV1WlhoaGJYQnNaUzVqYjIwd0hoY05NVGN4TVRJNU1Ua3lOREEyV2hjTk1qY3hNVEkzTVRreU5EQTIKV2pCek1Rc3dDUVlEVlFRR0V3SlZVekVUTUJFR0ExVUVDQk1LUTJGc2FXWnZjbTVwWVRFV01CUUdBMVVFQnhNTgpVMkZ1SUVaeVlXNWphWE5qYnpFWk1CY0dBMVVFQ2hNUWIzSm5NUzVsZUdGdGNHeGxMbU52YlRFY01Cb0dBMVVFCkF4TVRZMkV1YjNKbk1TNWxlR0Z0Y0d4bExtTnZiVEJaTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUEKQkJiTTVZS3B6UmlEbDdLWWFpSDVsVnBIeEl1TDEyaUcyWGhkMHRpbEg3MEljMGFpRUh1dG9rTkZsUXAzTWI0Zgpvb0M2bFVXWnRnRDJwMzZFNThMYkdqK2pYekJkTUE0R0ExVWREd0VCL3dRRUF3SUJwakFQQmdOVkhTVUVDREFHCkJnUlZIU1VBTUE4R0ExVWRFd0VCL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSUdJSVJwUWR0QldYd1dEODRGenEKT0xPM1VtT1ZyQ1NRMkpaTnk5cVBiN0FqTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUdlS2VZL1BsdGlWQTRPSgpRTWdwcDRvaGRMcGxKUFpzNERYS0NuOE9BZG9YQWlCK2g5TFdsR3ZsSDdtNkVpMXVRcDFld2ZESmxsZi9MZXczClgxaDNRY0VMZ3c9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                  ],
                  "tls_root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNTVENDQWZDZ0F3SUJBZ0lSQUtsNEFQWmV6dWt0Nk8wYjRyYjY5Y0F3Q2dZSUtvWkl6ajBFQXdJd2RqRUwKTUFrR0ExVUVCaE1DVlZNeEV6QVJCZ05WQkFnVENrTmhiR2xtYjNKdWFXRXhGakFVQmdOVkJBY1REVk5oYmlCRwpjbUZ1WTJselkyOHhHVEFYQmdOVkJBb1RFRzl5WnpFdVpYaGhiWEJzWlM1amIyMHhIekFkQmdOVkJBTVRGblJzCmMyTmhMbTl5WnpFdVpYaGhiWEJzWlM1amIyMHdIaGNOTVRjeE1USTVNVGt5TkRBMldoY05NamN4TVRJM01Ua3kKTkRBMldqQjJNUXN3Q1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRQpCeE1OVTJGdUlFWnlZVzVqYVhOamJ6RVpNQmNHQTFVRUNoTVFiM0puTVM1bGVHRnRjR3hsTG1OdmJURWZNQjBHCkExVUVBeE1XZEd4elkyRXViM0puTVM1bGVHRnRjR3hsTG1OdmJUQlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDkKQXdFSEEwSUFCSnNpQXVjYlcrM0lqQ2VaaXZPakRiUmFyVlRjTW9TRS9mSnQyU0thR1d5bWQ0am5xM25MWC9vVApCVmpZb21wUG1QbGZ4R0VSWHl0UTNvOVZBL2hwNHBlalh6QmRNQTRHQTFVZER3RUIvd1FFQXdJQnBqQVBCZ05WCkhTVUVDREFHQmdSVkhTVUFNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdLUVlEVlIwT0JDSUVJSnlqZnFoa0FvY3oKdkRpNnNGSGFZL1Bvd2tPWkxPMHZ0VGdFRnVDbUpFalZNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJRjVOVVdCVgpmSjgrM0lxU3J1NlFFbjlIa0lsQ0xDMnlvWTlaNHBWMnpBeFNBaUE5NWQzeDhBRXZIcUFNZnIxcXBOWHZ1TW5BCmQzUXBFa1gyWkh3ODZlQlVQZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                  ]
                },
                "type": 0
              },
              "version": "0"
            }
          },
          "version": "1"
        },
        "Org2MSP": {
          "mod_policy": "Admins",
          "policies": {
            "Admins": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org2MSP",
                        "role": "ADMIN"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Readers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org2MSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Writers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org2MSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            }
          },
          "values": {
            "AnchorPeers": {
              "mod_policy": "Admins",
              "value": {
                "anchor_peers": [
                  {
                    "host": "peer0.org2.example.com",
                    "port": 9051
                  }
                ]
              },
              "version": "0"
            },
            "MSP": {
              "mod_policy": "Admins",
              "value": {
                "config": {
                  "admins": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNHVENDQWNDZ0F3SUJBZ0lSQU5Pb1lIbk9seU94dTJxZFBteStyV293Q2dZSUtvWkl6ajBFQXdJd2N6RUwKTUFrR0ExVUVCaE1DVlZNeEV6QVJCZ05WQkFnVENrTmhiR2xtYjNKdWFXRXhGakFVQmdOVkJBY1REVk5oYmlCRwpjbUZ1WTJselkyOHhHVEFYQmdOVkJBb1RFRzl5WnpJdVpYaGhiWEJzWlM1amIyMHhIREFhQmdOVkJBTVRFMk5oCkxtOXlaekl1WlhoaGJYQnNaUzVqYjIwd0hoY05NVGN4TVRJNU1Ua3lOREEyV2hjTk1qY3hNVEkzTVRreU5EQTIKV2pCYk1Rc3dDUVlEVlFRR0V3SlZVekVUTUJFR0ExVUVDQk1LUTJGc2FXWnZjbTVwWVRFV01CUUdBMVVFQnhNTgpVMkZ1SUVaeVlXNWphWE5qYnpFZk1CMEdBMVVFQXd3V1FXUnRhVzVBYjNKbk1pNWxlR0Z0Y0d4bExtTnZiVEJaCk1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUhBMElBQkh1M0ZWMGlqdFFzckpsbnBCblgyRy9ickFjTHFJSzgKVDFiSWFyZlpvSkhtQm5IVW11RTBhc1dyKzM4VUs0N3hyczNZMGMycGhFVjIvRnhHbHhXMUZubWpUVEJMTUE0RwpBMVVkRHdFQi93UUVBd0lIZ0RBTUJnTlZIUk1CQWY4RUFqQUFNQ3NHQTFVZEl3UWtNQ0tBSU1pSzdteFpnQVVmCmdrN0RPTklXd2F4YktHVGdLSnVSNjZqVmordHZEV3RUTUFvR0NDcUdTTTQ5QkFNQ0EwY0FNRVFDSUQxaEtRdk8KVWxyWmVZMmZZY1N2YWExQmJPM3BVb3NxL2tZVElyaVdVM1J3QWlBR29mWmVPUFByWXVlTlk0Z2JCV2tjc3lpZgpNMkJmeXQwWG9NUThyT2VidUE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                  ],
                  "crypto_config": {
                    "identity_identifier_hash_function": "SHA256",
                    "signature_hash_family": "SHA2"
                  },
                  "name": "Org2MSP",
                  "root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNSRENDQWVxZ0F3SUJBZ0lSQU1pVXk5SGRSbXB5MDdsSjhRMlZNWXN3Q2dZSUtvWkl6ajBFQXdJd2N6RUwKTUFrR0ExVUVCaE1DVlZNeEV6QVJCZ05WQkFnVENrTmhiR2xtYjNKdWFXRXhGakFVQmdOVkJBY1REVk5oYmlCRwpjbUZ1WTJselkyOHhHVEFYQmdOVkJBb1RFRzl5WnpJdVpYaGhiWEJzWlM1amIyMHhIREFhQmdOVkJBTVRFMk5oCkxtOXlaekl1WlhoaGJYQnNaUzVqYjIwd0hoY05NVGN4TVRJNU1Ua3lOREEyV2hjTk1qY3hNVEkzTVRreU5EQTIKV2pCek1Rc3dDUVlEVlFRR0V3SlZVekVUTUJFR0ExVUVDQk1LUTJGc2FXWnZjbTVwWVRFV01CUUdBMVVFQnhNTgpVMkZ1SUVaeVlXNWphWE5qYnpFWk1CY0dBMVVFQ2hNUWIzSm5NaTVsZUdGdGNHeGxMbU52YlRFY01Cb0dBMVVFCkF4TVRZMkV1YjNKbk1pNWxlR0Z0Y0d4bExtTnZiVEJaTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEEwSUEKQk50YW1PY1hyaGwrQ2hzYXNSeklNWjV3OHpPWVhGcXhQbGV0a3d5UHJrbHpKWE01Qjl4QkRRVWlWNldJS2tGSwo0Vmd5RlNVWGZqaGdtd25kMUNBVkJXaWpYekJkTUE0R0ExVWREd0VCL3dRRUF3SUJwakFQQmdOVkhTVUVDREFHCkJnUlZIU1VBTUE4R0ExVWRFd0VCL3dRRk1BTUJBZjh3S1FZRFZSME9CQ0lFSU1pSzdteFpnQVVmZ2s3RE9OSVcKd2F4YktHVGdLSnVSNjZqVmordHZEV3RUTUFvR0NDcUdTTTQ5QkFNQ0EwZ0FNRVVDSVFEQ3FFRmFqeU5IQmVaRworOUdWVkNFNWI1YTF5ZlhvS3lkemdLMVgyOTl4ZmdJZ05BSUUvM3JINHFsUE9HbjdSS3Yram9WaUNHS2t6L0F1Cm9FNzI4RWR6WmdRPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                  ],
                  "tls_root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNTakNDQWZDZ0F3SUJBZ0lSQU9JNmRWUWMraHBZdkdMSlFQM1YwQU13Q2dZSUtvWkl6ajBFQXdJd2RqRUwKTUFrR0ExVUVCaE1DVlZNeEV6QVJCZ05WQkFnVENrTmhiR2xtYjNKdWFXRXhGakFVQmdOVkJBY1REVk5oYmlCRwpjbUZ1WTJselkyOHhHVEFYQmdOVkJBb1RFRzl5WnpJdVpYaGhiWEJzWlM1amIyMHhIekFkQmdOVkJBTVRGblJzCmMyTmhMbTl5WnpJdVpYaGhiWEJzWlM1amIyMHdIaGNOTVRjeE1USTVNVGt5TkRBMldoY05NamN4TVRJM01Ua3kKTkRBMldqQjJNUXN3Q1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRQpCeE1OVTJGdUlFWnlZVzVqYVhOamJ6RVpNQmNHQTFVRUNoTVFiM0puTWk1bGVHRnRjR3hsTG1OdmJURWZNQjBHCkExVUVBeE1XZEd4elkyRXViM0puTWk1bGVHRnRjR3hsTG1OdmJUQlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDkKQXdFSEEwSUFCTWZ1QTMwQVVBT1ZKRG1qVlBZd1lNbTlweW92MFN6OHY4SUQ5N0twSHhXOHVOOUdSOU84aVdFMgo5bllWWVpiZFB2V1h1RCszblpweUFNcGZja3YvYUV5alh6QmRNQTRHQTFVZER3RUIvd1FFQXdJQnBqQVBCZ05WCkhTVUVDREFHQmdSVkhTVUFNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdLUVlEVlIwT0JDSUVJRnk5VHBHcStQL08KUGRXbkZXdWRPTnFqVDRxOEVKcDJmbERnVCtFV2RnRnFNQW9HQ0NxR1NNNDlCQU1DQTBnQU1FVUNJUUNZYlhSeApXWDZoUitPU0xBNSs4bFRwcXRMWnNhOHVuS3J3ek1UYXlQUXNVd0lnVSs5YXdaaE0xRzg3bGE0V0h4cmt5eVZ2CkU4S1ZsR09IVHVPWm9TMU5PT0U9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                  ]
                },
                "type": 0
              },
              "version": "0"
            }
          },
          "version": "1"
        },
        "Org3MSP": {
          "groups": {},
          "mod_policy": "Admins",
          "policies": {
            "Admins": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org3MSP",
                        "role": "ADMIN"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Readers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org3MSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Writers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "Org3MSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            }
          },
          "values": {
            "MSP": {
              "mod_policy": "Admins",
              "value": {
                "config": {
                  "admins": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNHRENDQWIrZ0F3SUJBZ0lRQUlSNWN4U0hpVm1kSm9uY3FJVUxXekFLQmdncWhrak9QUVFEQWpCek1Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RVpNQmNHQTFVRUNoTVFiM0puTXk1bGVHRnRjR3hsTG1OdmJURWNNQm9HQTFVRUF4TVRZMkV1CmIzSm5NeTVsZUdGdGNHeGxMbU52YlRBZUZ3MHhOekV4TWpreE9UTTRNekJhRncweU56RXhNamN4T1RNNE16QmEKTUZzeEN6QUpCZ05WQkFZVEFsVlRNUk13RVFZRFZRUUlFd3BEWVd4cFptOXlibWxoTVJZd0ZBWURWUVFIRXcxVApZVzRnUm5KaGJtTnBjMk52TVI4d0hRWURWUVFEREJaQlpHMXBia0J2Y21jekxtVjRZVzF3YkdVdVkyOXRNRmt3CkV3WUhLb1pJemowQ0FRWUlLb1pJemowREFRY0RRZ0FFSFlkVFY2ZC80cmR4WFd2cm1qZ0hIQlhXc2lxUWxrcnQKZ0p1NzMxcG0yZDRrWU82aEd2b2tFRFBwbkZFdFBwdkw3K1F1UjhYdkFQM0tqTkt0NHdMRG5hTk5NRXN3RGdZRApWUjBQQVFIL0JBUURBZ2VBTUF3R0ExVWRFd0VCL3dRQ01BQXdLd1lEVlIwakJDUXdJb0FnSWNxUFVhM1VQNmN0Ck9LZmYvKzVpMWJZVUZFeVFlMVAyU0hBRldWSWUxYzB3Q2dZSUtvWkl6ajBFQXdJRFJ3QXdSQUlnUm5LRnhsTlYKSmppVGpkZmVoczRwNy9qMkt3bFVuUWVuNFkyUnV6QjFrbm9DSUd3dEZ1TEdpRFY2THZSL2pHVXR3UkNyeGw5ZApVNENCeDhGbjBMdXNMTkJYCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                  ],
                  "crypto_config": {
                    "identity_identifier_hash_function": "SHA256",
                    "signature_hash_family": "SHA2"
                  },
                  "name": "Org3MSP",
                  "root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNRakNDQWVtZ0F3SUJBZ0lRUkN1U2Y0RVJNaDdHQW1ydTFIQ2FZREFLQmdncWhrak9QUVFEQWpCek1Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RVpNQmNHQTFVRUNoTVFiM0puTXk1bGVHRnRjR3hsTG1OdmJURWNNQm9HQTFVRUF4TVRZMkV1CmIzSm5NeTVsZUdGdGNHeGxMbU52YlRBZUZ3MHhOekV4TWpreE9UTTRNekJhRncweU56RXhNamN4T1RNNE16QmEKTUhNeEN6QUpCZ05WQkFZVEFsVlRNUk13RVFZRFZRUUlFd3BEWVd4cFptOXlibWxoTVJZd0ZBWURWUVFIRXcxVApZVzRnUm5KaGJtTnBjMk52TVJrd0Z3WURWUVFLRXhCdmNtY3pMbVY0WVcxd2JHVXVZMjl0TVJ3d0dnWURWUVFECkV4TmpZUzV2Y21jekxtVjRZVzF3YkdVdVkyOXRNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUUKZXFxOFFQMnllM08vM1J3UzI0SWdtRVdST3RnK3Zyc2pRY1BvTU42NEZiUGJKbmExMklNaVdDUTF6ZEZiTU9hSAorMUlrb21yY0RDL1ZpejkvY0M0NW9xTmZNRjB3RGdZRFZSMFBBUUgvQkFRREFnR21NQThHQTFVZEpRUUlNQVlHCkJGVWRKUUF3RHdZRFZSMFRBUUgvQkFVd0F3RUIvekFwQmdOVkhRNEVJZ1FnSWNxUFVhM1VQNmN0T0tmZi8rNWkKMWJZVUZFeVFlMVAyU0hBRldWSWUxYzB3Q2dZSUtvWkl6ajBFQXdJRFJ3QXdSQUlnTEgxL2xSZElWTVA4Z2FWeQpKRW01QWQ0SjhwZ256N1BVV2JIMzZvdVg4K1lDSUNPK20vUG9DbDRIbTlFbXhFN3ZnUHlOY2trVWd0SlRiTFhqCk5SWjBxNTdWCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                  ],
                  "tls_root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNTVENDQWZDZ0F3SUJBZ0lSQU9xc2JQQzFOVHJzclEvUUNpalh6K0F3Q2dZSUtvWkl6ajBFQXdJd2RqRUwKTUFrR0ExVUVCaE1DVlZNeEV6QVJCZ05WQkFnVENrTmhiR2xtYjNKdWFXRXhGakFVQmdOVkJBY1REVk5oYmlCRwpjbUZ1WTJselkyOHhHVEFYQmdOVkJBb1RFRzl5WnpNdVpYaGhiWEJzWlM1amIyMHhIekFkQmdOVkJBTVRGblJzCmMyTmhMbTl5WnpNdVpYaGhiWEJzWlM1amIyMHdIaGNOTVRjeE1USTVNVGt6T0RNd1doY05NamN4TVRJM01Ua3oKT0RNd1dqQjJNUXN3Q1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRQpCeE1OVTJGdUlFWnlZVzVqYVhOamJ6RVpNQmNHQTFVRUNoTVFiM0puTXk1bGVHRnRjR3hsTG1OdmJURWZNQjBHCkExVUVBeE1XZEd4elkyRXViM0puTXk1bGVHRnRjR3hsTG1OdmJUQlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDkKQXdFSEEwSUFCSVJTTHdDejdyWENiY0VLMmhxSnhBVm9DaDhkejNqcnA5RHMyYW9TQjBVNTZkSUZhVmZoR2FsKwovdGp6YXlndXpFalFhNlJ1MmhQVnRGM2NvQnJ2Ulpxalh6QmRNQTRHQTFVZER3RUIvd1FFQXdJQnBqQVBCZ05WCkhTVUVDREFHQmdSVkhTVUFNQThHQTFVZEV3RUIvd1FGTUFNQkFmOHdLUVlEVlIwT0JDSUVJQ2FkVERGa0JPTGkKblcrN2xCbDExL3pPbXk4a1BlYXc0MVNZWEF6cVhnZEVNQW9HQ0NxR1NNNDlCQU1DQTBjQU1FUUNJQlgyMWR3UwpGaG5NdDhHWXUweEgrUGd5aXQreFdQUjBuTE1Jc1p2dVlRaktBaUFLUlE5N2VrLzRDTzZPWUtSakR0VFM4UFRmCm9nTmJ6dTBxcThjbVhseW5jZz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
                  ]
                },
                "type": 0
              },
              "version": "0"
            }
          },
          "version": "0"
        }
      },
      "mod_policy": "Admins",
      "policies": {
        "Admins": {
          "mod_policy": "Admins",
          "policy": {
            "type": 3,
            "value": {
              "rule": "MAJORITY",
              "sub_policy": "Admins"
            }
          },
          "version": "0"
        },
        "Readers": {
          "mod_policy": "Admins",
          "policy": {
            "type": 3,
            "value": {
              "rule": "ANY",
              "sub_policy": "Readers"
            }
          },
          "version": "0"
        },
        "Writers": {
          "mod_policy": "Admins",
          "policy": {
            "type": 3,
            "value": {
              "rule": "ANY",
              "sub_policy": "Writers"
            }
          },
          "version": "0"
        }
      },
      "version": "1"
    },
    "Orderer": {
      "groups": {
        "OrdererOrg": {
          "mod_policy": "Admins",
          "policies": {
            "Admins": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "OrdererMSP",
                        "role": "ADMIN"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Readers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "OrdererMSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            },
            "Writers": {
              "mod_policy": "Admins",
              "policy": {
                "type": 1,
                "value": {
                  "identities": [
                    {
                      "principal": {
                        "msp_identifier": "OrdererMSP",
                        "role": "MEMBER"
                      },
                      "principal_classification": "ROLE"
                    }
                  ],
                  "rule": {
                    "n_out_of": {
                      "n": 1,
                      "rules": [
                        {
                          "signed_by": 0
                        }
                      ]
                    }
                  },
                  "version": 0
                }
              },
              "version": "0"
            }
          },
          "values": {
            "MSP": {
              "mod_policy": "Admins",
              "value": {
                "config": {
                  "admins": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNDakNDQWJDZ0F3SUJBZ0lRSFNTTnIyMWRLTTB6THZ0dEdoQnpMVEFLQmdncWhrak9QUVFEQWpCcE1Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RVVNQklHQTFVRUNoTUxaWGhoYlhCc1pTNWpiMjB4RnpBVkJnTlZCQU1URG1OaExtVjRZVzF3CmJHVXVZMjl0TUI0WERURTNNVEV5T1RFNU1qUXdObG9YRFRJM01URXlOekU1TWpRd05sb3dWakVMTUFrR0ExVUUKQmhNQ1ZWTXhFekFSQmdOVkJBZ1RDa05oYkdsbWIzSnVhV0V4RmpBVUJnTlZCQWNURFZOaGJpQkdjbUZ1WTJsegpZMjh4R2pBWUJnTlZCQU1NRVVGa2JXbHVRR1Y0WVcxd2JHVXVZMjl0TUZrd0V3WUhLb1pJemowQ0FRWUlLb1pJCnpqMERBUWNEUWdBRTZCTVcvY0RGUkUvakFSenV5N1BjeFQ5a3pnZitudXdwKzhzK2xia0hZd0ZpaForMWRhR3gKKzhpS1hDY0YrZ0tpcVBEQXBpZ2REOXNSeTBoTEMwQnRacU5OTUVzd0RnWURWUjBQQVFIL0JBUURBZ2VBTUF3RwpBMVVkRXdFQi93UUNNQUF3S3dZRFZSMGpCQ1F3SW9BZ3o3bDQ2ZXRrODU0NFJEanZENVB6YjV3TzI5N0lIMnNUCngwTjAzOHZibkpzd0NnWUlLb1pJemowRUF3SURTQUF3UlFJaEFNRTJPWXljSnVyYzhVY2hkeTA5RU50RTNFUDIKcVoxSnFTOWVCK0gxSG5FSkFpQUtXa2h5TmI0akRPS2MramJIVmgwV0YrZ3J4UlJYT1hGaEl4ei85elI3UUE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                  ],
                  "crypto_config": {
                    "identity_identifier_hash_function": "SHA256",
                    "signature_hash_family": "SHA2"
                  },
                  "name": "OrdererMSP",
                  "root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNMakNDQWRXZ0F3SUJBZ0lRY2cxUVZkVmU2Skd6YVU1cmxjcW4vakFLQmdncWhrak9QUVFEQWpCcE1Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RVVNQklHQTFVRUNoTUxaWGhoYlhCc1pTNWpiMjB4RnpBVkJnTlZCQU1URG1OaExtVjRZVzF3CmJHVXVZMjl0TUI0WERURTNNVEV5T1RFNU1qUXdObG9YRFRJM01URXlOekU1TWpRd05sb3dhVEVMTUFrR0ExVUUKQmhNQ1ZWTXhFekFSQmdOVkJBZ1RDa05oYkdsbWIzSnVhV0V4RmpBVUJnTlZCQWNURFZOaGJpQkdjbUZ1WTJsegpZMjh4RkRBU0JnTlZCQW9UQzJWNFlXMXdiR1V1WTI5dE1SY3dGUVlEVlFRREV3NWpZUzVsZUdGdGNHeGxMbU52CmJUQlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJQTVI2MGdCcVJham9hS0U1TExRYjRIb28wN3QKYTRuM21Ncy9NRGloQVQ5YUN4UGZBcDM5SS8wMmwvZ2xiMTdCcEtxZGpGd0JKZHNuMVN6ZnQ3NlZkTitqWHpCZApNQTRHQTFVZER3RUIvd1FFQXdJQnBqQVBCZ05WSFNVRUNEQUdCZ1JWSFNVQU1BOEdBMVVkRXdFQi93UUZNQU1CCkFmOHdLUVlEVlIwT0JDSUVJTSs1ZU9uclpQT2VPRVE0N3crVDgyK2NEdHZleUI5ckU4ZERkTi9MMjV5Yk1Bb0cKQ0NxR1NNNDlCQU1DQTBjQU1FUUNJQVB6SGNOUmQ2a3QxSEdpWEFDclFTM0grL3R5NmcvVFpJa1pTeXIybmdLNQpBaUJnb1BVTTEwTHNsMVFtb2dlbFBjblZGZjJoODBXR2I3NGRIS2tzVFJKUkx3PT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
                  ],
                  "tls_root_certs": [
                    "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNORENDQWR1Z0F3SUJBZ0lRYWJ5SUl6cldtUFNzSjJacisvRVpXVEFLQmdncWhrak9QUVFEQWpCc01Rc3cKQ1FZRFZRUUdFd0pWVXpFVE1CRUdBMVVFQ0JNS1EyRnNhV1p2Y201cFlURVdNQlFHQTFVRUJ4TU5VMkZ1SUVaeQpZVzVqYVhOamJ6RVVNQklHQTFVRUNoTUxaWGhoYlhCc1pTNWpiMjB4R2pBWUJnTlZCQU1URVhSc2MyTmhMbVY0CllXMXdiR1V1WTI5dE1CNFhEVEUzTVRFeU9URTVNalF3TmxvWERUSTNNVEV5TnpFNU1qUXdObG93YkRFTE1Ba0cKQTFVRUJoTUNWVk14RXpBUkJnTlZCQWdUQ2tOaGJHbG1iM0p1YVdFeEZqQVVCZ05WQkFjVERWTmhiaUJHY21GdQpZMmx6WTI4eEZEQVNCZ05WQkFvVEMyVjRZVzF3YkdVdVkyOXRNUm93R0FZRFZRUURFeEYwYkhOallTNWxlR0Z0CmNHeGxMbU52YlRCWk1CTUdCeXFHU000OUFnRUdDQ3FHU000OUF3RUhBMElBQkVZVE9mdG1rTHdiSlRNeG1aVzMKZVdqRUQ2eW1UeEhYeWFQdTM2Y1NQWDlldDZyU3Y5UFpCTGxyK3hZN1dtYlhyOHM5K3E1RDMwWHl6OEh1OWthMQpSc1dqWHpCZE1BNEdBMVVkRHdFQi93UUVBd0lCcGpBUEJnTlZIU1VFQ0RBR0JnUlZIU1VBTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0tRWURWUjBPQkNJRUlJcjduNTVjTWlUdENEYmM5UGU0RFpnZ0ZYdHV2RktTdnBNYUhzbzAKSnpFd01Bb0dDQ3FHU000OUJBTUNBMGNBTUVRQ0lGM1gvMGtQRkFVQzV2N25JVVh6SmI5Z3JscWxET05UeVg2QQpvcmtFVTdWb0FpQkpMbS9IUFZ0aVRHY2NldUZPZTE4SnNwd0JTZ1hxNnY1K1BobEdsbU9pWHc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
                  ]
                },
                "type": 0
              },
              "version": "0"
            }
          },
          "version": "0"
        }
      },
      "mod_policy": "Admins",
      "policies": {
        "Admins": {
          "mod_policy": "Admins",
          "policy": {
            "type": 3,
            "value": {
              "rule": "MAJORITY",
              "sub_policy": "Admins"
            }
          },
          "version": "0"
        },
        "BlockValidation": {
          "mod_policy": "Admins",
          "policy": {
            "type": 3,
            "value": {
              "rule": "ANY",
              "sub_policy": "Writers"
            }
          },
          "version": "0"
        },
        "Readers": {
          "mod_policy": "Admins",
          "policy": {
            "type": 3,
            "value": {
              "rule": "ANY",
              "sub_policy": "Readers"
            }
          },
          "version": "0"
        },
        "Writers": {
          "mod_policy": "Admins",
          "policy": {
            "type": 3,
            "value": {
              "rule": "ANY",
              "sub_policy": "Writers"
            }
          },
          "version": "0"
        }
      },
      "values": {
        "BatchSize": {
          "mod_policy": "Admins",
          "value": {
            "absolute_max_bytes": 103809024,
            "max_message_count": 10,
            "preferred_max_bytes": 524288
          },
          "version": "0"
        },
        "BatchTimeout": {
          "mod_policy": "Admins",
          "value": {
            "timeout": "2s"
          },
          "version": "0"
        },
        "ChannelRestrictions": {
          "mod_policy": "Admins",
          "version": "0"
        },
        "ConsensusType": {
          "mod_policy": "Admins",
          "value": {
            "type": "solo"
          },
          "version": "0"
        }
      },
      "version": "0"
    }
  },
  "mod_policy": "",
  "policies": {
    "Admins": {
      "mod_policy": "Admins",
      "policy": {
        "type": 3,
        "value": {
          "rule": "MAJORITY",
          "sub_policy": "Admins"
        }
      },
      "version": "0"
    },
    "Readers": {
      "mod_policy": "Admins",
      "policy": {
        "type": 3,
        "value": {
          "rule": "ANY",
          "sub_policy": "Readers"
        }
      },
      "version": "0"
    },
    "Writers": {
      "mod_policy": "Admins",
      "policy": {
        "type": 3,
        "value": {
          "rule": "ANY",
          "sub_policy": "Writers"
        }
      },
      "version": "0"
    }
  },
  "values": {
    "BlockDataHashingStructure": {
      "mod_policy": "Admins",
      "value": {
        "width": 4294967295
      },
      "version": "0"
    },
    "Consortium": {
      "mod_policy": "Admins",
      "value": {
        "name": "SampleConsortium"
      },
      "version": "0"
    },
    "HashingAlgorithm": {
      "mod_policy": "Admins",
      "value": {
        "name": "SHA256"
      },
      "version": "0"
    },
    "OrdererAddresses": {
      "mod_policy": "/Channel/Orderer/Admins",
      "value": {
        "addresses": [
          "orderer.example.com:7050"
        ]
      },
      "version": "0"
    }
  },
  "version": "0"
},
"sequence": "3",
"type": 0
}
```

</div>
</details>

변경 가능한 채널 구성 요소 값들은 다음과 같다.

- Batch Size: 블록의 트랜잭션 수 또는 크기
    ```json
    {
        "absolute_max_bytes": 102760448,   # 블록의 최대 크기
        "max_message_count": 10,           # 블록 내 최대 트랜잭션 수
        "preferred_max_bytes": 524288      # 적정 블록 크기, 이보다 크면 블록을 나누어 저장
    }
    ```
- Batch Timeout: 블록 생성 주기. 트랜잭션 저장 이후에 다음 트랜잭션을 기다리는 시간
    ```json
    { "timeout": "2s" }     # 너무 빠르면 블록이 자주 생성됨, 블록이 낭비되고 처리량은 감소함
    ```
- Channel Restrictions: 오더러에서 할당할 수 있는 총 채널 갯수
    ```json
    { "max_count":1000 }
    ```
- Channel Creation Policy: 새로운 채널의 응용프로그램 그룹 내에 정의된 mod_policy 값
    ```json
    {
        "type": 3,
        "value": {
            "rule": "ANY",
            "sub_policy": "Admins"
        }
    }
    ```
    - 오더러 시스템 채널에서만 설정 가능
- Kafka brokers: Kafka 환경에서의 broker 목록
    ```json
    {
        "brokers": [
            "kafka0:9092",
            "kafka1:9092",
            "kafka2:9092",
            "kafka3:9092"
        ]
    }
    ```
    - **Genesis 블록이 생성된 이후, 컨센서스(solo, kafka, raft)의 변경은 불가능하다.**
- Anchor Peers Definition: 각 org의 앵커피어 위치
    ```json
    {
        "host": "peer0.org2.example.com",
        "port": 9051
    }
    ```
- Hashing Structure: 블록 데이터의 해시값(머클 트리) 크기
    ```json
    { "width": 4294967295 } # 일반적으로 이 값은 고정되어 있음
    ```
- Hashing Algorithm: 블록으로 인코딩 된 해시 값 계산에 사용되는 알고리즘
    ```json
    { "name": "SHA256" }    # SHA256에서 변경 불가능
    ```
- Block Validation: 블록 유효성 검증 과정에 필요한 요구사항
    ```json
    {
        "type": 3,
        "value": { 
            "rule": "ANY",
            "sub_policy": "Writers"
        }
    }
    ```
- Orderer Address: 오더러의 주소 목록
    ```json
    {
        "addresses": [
            "orderer.example.com:7050"
        ]
    }
    ```

<br>

## Source

BYFN(Build Your First Network) 기반으로 진행하였다.

<br>

### 1. cli 
```bash
docker exec -it cli /bin/bash
```

### 2. 환경변수 설정
peer0.org1.example.com에서 실행한다.
```bash
export CHANNEL_NAME=mychannel
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_ADDRESS=peer0.org1.example.com:7051
```

### 3. 채널 fetch
```bash
peer channel fetch config config_block.pb -o orderer.example.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

### 4. 블록파일 JSON 형태로 변환
```bash
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json
```

### 5. 값을 변경할 사본 생성
```bash
cp config.json modified_config.json</code></pre>
```

### 6. 값 변경
```bash
vim modified_config.json
```
```json
    ...
        "values": {
          "BatchSize": {
            "mod_policy": "Admins",
            "value": {
              "absolute_max_bytes": 103809024,
              "max_message_count": 10,
              "preferred_max_bytes": 524288
            },
            "version": "0"
          }
    ...
```
- max_message_count : 10 -> 11

### 7. modified_config.json 파일을 블록으로 변환
```bash
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
```

### 8. config.json 파일을 config.pb 블록파일로 변환
```bash
configtxlator proto_encode --input config.json --type common.Config --output config.pb
```

### 9. 수정 전후 delta 값 비교
```bash
configtxlator compute_update --channel_id mychannel --original config.pb --updated modified_config.pb --output diff_config.pb
```

## 10. 블록 파일(diff_config.pb)을 JSON 형태로 변환
```bash
configtxlator proto_decode --input diff_config.pb --type common.ConfigUpdate | jq . > diff_config.json
```

### 11. diff_config.json 파일에 헤더 값(채널 정보) 추가
```bash
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat diff_config.json)'}}}' | jq . > diff_config_envelope.json
```

### 12. 헤더 정보 붙인 값을 블록 파일로 변환
```bash
configtxlator proto_encode --input diff_config_envelope.json --type common.Envelope --output diff_config_envelope.pb
```

### 13. 최종 변경된 내용 오더러로 사인
```bash
export CORE_PEER_ADDRESS=orderer.example.com:7050
export CORE_PEER_LOCALMSPID="OrdererMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin\@example.com/msp

peer channel signconfigtx -f diff_config_envelope.pb
```

## 14. 채널 업데이트
```bash
peer channel update -f diff_config_envelope.pb -c mychannel -o orderer.example.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
```

### 15. 결과 확인
```bash
peer channel fetch config config_block2.pb -o orderer.example.com:7050 -c mychannel --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

configtxlator proto_decode --input config_block2.pb --type common.Block | jq .data.data[0].payload.data.config > config2.json

vim config2.json
```

- config2.json : line 590
    ```json
    ...
        "values": {
          "BatchSize": {
            "mod_policy": "Admins",
            "value": {
              "absolute_max_bytes": 103809024,
              "max_message_count": 11,
              "preferred_max_bytes": 524288
            },
            "version": "0"
          }
    ...
    ```
    - 값이 변경되어 있음을 확인할 수 있다.