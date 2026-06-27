# Motor Insurance — Happy Path

**Pattern:** `motor-insurance/v1`  
**Sector:** FIN-03 Insurance

---

## Scenario

Budi owns a 2022 Toyota Avanza and wants to purchase comprehensive motor insurance. He uses an insurance aggregator app (BAP) to browse products from OJK-licensed insurers (BPP). He selects an all-risk policy, completes KYC, passes vehicle underwriting, pays the premium, and receives a digital policy certificate.

---

## Step-by-Step Flow

### Phase 1 — Catalog

**1. publish_catalog** *(BPP → ION Catalog)*

Insurer Asuransi Maju Tbk publishes its motor insurance products to the ION catalog:

```json
{
  "context": {
    "domain": "ion:finance",
    "action": "publish_catalog",
    "bppId": "asuransi-maju.ion.id"
  },
  "message": {
    "catalog": {
      "provider": {
        "id": "asuransi-maju",
        "descriptor": { "name": "Asuransi Maju Tbk" },
        "providerAttributes": {
          "ojkLicenseNumber": "KEP-1234/KM.13/2023",
          "ojkLicenseType": "ASURANSI_UMUM"
        }
      },
      "resources": [
        {
          "id": "amaju-motor-comprehensive-v1",
          "crc": "FNC-insurance",
          "resourceAttributes": {
            "@context": "https://schema.ion.id/finance/insurance-resource/v1/context.jsonld",
            "@type": "ion:InsuranceProduct",
            "productType": "MOTOR_COMPREHENSIVE",
            "vehicleType": "FOUR_WHEELER",
            "tariffZone": "ZONE_2",
            "premiumRateRange": { "min": 1.05, "max": 1.78 },
            "coverageInclusions": ["PARTIAL_LOSS", "TOTAL_LOSS", "THIRD_PARTY_LIABILITY"],
            "ojkProductCode": "AUMK-001"
          }
        }
      ]
    }
  }
}
```

---

### Phase 2 — Transaction

**2. search** *(BAP → BPP)*

Budi searches for comprehensive coverage for his 2022 Toyota Avanza in Jakarta (Zone 2):

```json
{
  "message": {
    "intent": {
      "resourceAttributes": {
        "productType": "MOTOR_COMPREHENSIVE",
        "vehicleType": "FOUR_WHEELER"
      },
      "offerAttributes": {
        "tariffZone": "ZONE_2"
      }
    }
  }
}
```

**3. on_search** *(BPP → BAP)*

Insurer returns matching products with indicative premium range:

```json
{
  "message": {
    "catalog": {
      "resources": [{
        "id": "amaju-motor-comprehensive-v1",
        "resourceAttributes": {
          "@type": "ion:InsuranceProduct",
          "productType": "MOTOR_COMPREHENSIVE",
          "premiumRateRange": { "min": 1.05, "max": 1.78 }
        }
      }]
    }
  }
}
```

**4. select** *(BAP → BPP)*

Budi selects the product and provides his vehicle details to get a precise quote:

```json
{
  "message": {
    "contract": {
      "commitments": [{ "offerId": "amaju-motor-comprehensive-v1" }],
      "contractAttributes": {
        "vehicleDetails": {
          "make": "Toyota",
          "model": "Avanza",
          "year": 2022,
          "vehicleIdNumber": "MHFM1BA3JJK123456",
          "licensePlate": "B 1234 ABC",
          "stnkNumber": "123456789",
          "condition": "NEW"
        }
      },
      "offerAttributes": {
        "insuredDeclaredValue": 210000000
      }
    }
  }
}
```

**5. on_select** *(BPP → BAP)*

Insurer runs underwriting (Zone 2, 2022 Avanza IDV IDR 210 juta) and returns the premium quote:

```json
{
  "message": {
    "contract": {
      "offerAttributes": {
        "@context": "https://schema.ion.id/finance/insurance-offer/v1/context.jsonld",
        "@type": "ion:PolicyQuote",
        "approvedIDV": 210000000,
        "annualPremiumIDR": 2730000,
        "ojkFinalRatePercent": 1.30,
        "tariffZone": "ZONE_2",
        "quoteValidUntil": "2026-06-24T23:59:59+07:00",
        "inclusions": ["PARTIAL_LOSS", "TOTAL_LOSS", "THIRD_PARTY_LIABILITY"],
        "specialExclusions": ["RACING", "OUTSIDE_INDONESIA"],
        "requiredDocuments": ["KTP_POLICYHOLDER", "STNK", "VEHICLE_PHOTOS_6_SIDES"]
      }
    }
  }
}
```

**6. init** *(BAP → BPP)*

Budi submits the full application — KYC data, vehicle ownership docs, 6-side photos, and payment method. This triggers the `underwriting` variant (vehicle inspection) and `kyc-verification` variant if not yet approved:

```json
{
  "message": {
    "contract": {
      "participants": [
        {
          "role": "POLICYHOLDER",
          "person": {
            "name": "Budi Santoso",
            "nik": "3171012345678901",
            "dateOfBirth": "1990-03-15",
            "driverLicenseType": "SIM_A"
          },
          "contact": { "phone": "+628112345678", "email": "budi@email.com" },
          "address": "Jl. Kebon Jeruk No. 10, Jakarta Barat"
        }
      ],
      "contractAttributes": {
        "vehicleDetails": {
          "make": "Toyota", "model": "Avanza", "year": 2022,
          "vehicleIdNumber": "MHFM1BA3JJK123456",
          "licensePlate": "B 1234 ABC",
          "stnkNumber": "123456789",
          "vehiclePhotos": ["https://storage.example.com/photo-front.jpg", "..."]
        },
        "inspectionMethod": "SELF_INSPECTION"
      },
      "offerAttributes": {
        "insuredDeclaredValue": 210000000
      }
    }
  }
}
```

**7. on_init** *(BPP → BAP)*

Insurer confirms underwriting passed, returns final premium breakdown and policy schedule draft:

```json
{
  "message": {
    "contract": {
      "contractAttributes": {
        "underwritingStatus": "APPROVED",
        "coverageStartDate": "2026-06-18",
        "coverageEndDate": "2027-06-17",
        "policyScheduleDraftUrl": "https://docs.asuransi-maju.co.id/draft/AMAJU-2026-00012.pdf"
      },
      "considerationAttributes": {
        "@context": "https://schema.ion.id/finance/insurance-consideration/v1/context.jsonld",
        "@type": "ion:PremiumConsideration",
        "totalPremiumIDR": 2840000,
        "currency": "IDR",
        "paymentFrequency": "ANNUAL",
        "breakup": [
          { "type": "BASE_PREMIUM", "amountIDR": 2730000 },
          { "type": "STAMP_DUTY", "amountIDR": 10000 },
          { "type": "ADMIN_FEE", "amountIDR": 100000 }
        ]
      }
    }
  }
}
```

**8. confirm** *(BAP → BPP)*

Budi accepts the terms and pays the premium:

```json
{
  "message": {
    "contract": {
      "participants": [{ "role": "POLICYHOLDER", "id": "budi-santoso-001" }],
      "contractAttributes": {
        "policyConsentRef": "CONSENT-2026-AMAJU-00012",
        "policyConsentSignedAt": "2026-06-17T14:30:00+07:00"
      },
      "settlements": [{
        "settlementAttributes": {
          "paymentMethod": "VIRTUAL_ACCOUNT",
          "paymentRef": "VA-BCA-1234567890",
          "amountPaidIDR": 2840000,
          "paidAt": "2026-06-17T14:31:00+07:00"
        }
      }]
    }
  }
}
```

**9. on_confirm** *(BPP → BAP)*

Insurer issues the policy. Budi receives his policy certificate:

```json
{
  "message": {
    "contract": {
      "id": "POL-AMAJU-2026-00012",
      "status": "ACTIVE",
      "contractAttributes": {
        "@context": "https://schema.ion.id/finance/insurance-contract/v1/context.jsonld",
        "@type": "ion:InsurancePolicy",
        "policyNumber": "POL-AMAJU-2026-00012",
        "certificateUrl": "https://docs.asuransi-maju.co.id/cert/AMAJU-2026-00012.pdf",
        "policyStatus": "ACTIVE",
        "coverageStartDate": "2026-06-18",
        "coverageEndDate": "2027-06-17",
        "sumInsuredIDR": 210000000,
        "actualIDV": 210000000
      },
      "performanceAttributes": {
        "@context": "https://schema.ion.id/finance/insurance-performance/v1/context.jsonld",
        "@type": "ion:PolicyPerformance",
        "coveragePeriodStart": "2026-06-18",
        "coveragePeriodEnd": "2027-06-17",
        "policyState": "ACTIVE",
        "nextRenewalDueDate": "2027-05-18"
      }
    }
  }
}
```

---

### Phase 3 — Fulfilment

**10. on_status[ACTIVE]** *(BPP → BAP)*

Policy is in force. No further BAP action required unless a claim occurs.

**11. on_status[RENEWAL_DUE]** *(BPP → BAP, T−30 days)*

Insurer sends renewal notice 30 days before expiry — triggers `policy-renewal` variant.

**12. on_status[EXPIRED]** *(BPP → BAP)*

Policy has expired without renewal. Contract complete.

---

### Phase 4 — Post-Fulfilment

- **rate** — Policyholder rates the insurance purchase experience
- **support** — Customer support for enquiries (certificate re-send, policy details, claim status)
- **reconcile** (ION extension) — Financial reconciliation of premium paid vs. commission/tax
- **raise** (ION extension) — Formal dispute escalation (OJK complaint, BPSK)
- **cancel** — Policy cancellation (only valid before `on_confirm`)
