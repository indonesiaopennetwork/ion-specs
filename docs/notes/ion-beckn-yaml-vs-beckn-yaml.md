## Fork of beckn.yaml within ION specs 

## Executive Summary
[ion-beckn.yaml](../../releases/release1/schema/core/api/v2.0.0/ion-beckn.yaml) is a fork of beckn.yaml with changes we need. You need to configure your ONIX configuration to point to this file instead of beckn.yaml. Also a few objects now have an improved structure. Transition your payload to benefit from it. 

## Introduction
ION is based on the Beckn protocol, authored and maintained by NFH. Version 2 of Beckn protocol is written such that the core protocol does not require changes and can be extended by Networks (such as ION) through Extension objects. Therefore the core protocol specification (beckn.yaml) does not modifications. However, there are still some gaps in beckn.yaml that needs to be fixed in that file. These have been raised as issues on the [protocol specifications repository](https://github.com/beckn/protocol-specifications-v2/issues). However the process of approval there takes time. So we have decided to copy beckn.yaml into our own repo and have made changes we needed. In a future release, once we see the NFH beckn.yaml being identical to this, we can then decide to use a vendored copy instead of our modified copy. 

## Improvments on beckn.yaml
The following are some of the primary improvements done to beckn.yaml.

1. Add {context,message} and {context,error}. Beckn 2.0 did not have a mechanism to return back business errors in the on_xxxx action responses. This was added to all the on_xxxx action schemas.
2. Commitment object had resources array with each item having id and quantity as required. However Resource object does not have quantity. It would work because Resource object had additionalProperties as true. This hid the error. Now the Commitment object has been modified with the array element containing Resource and Quantity.
3. The track action and on_track response had the same object(Tracking). Ideally track action had to have a TrackRequest object. This is already in the nfh schema, but was not used in beckn.yaml.

The following are some of the improvements done to schema objects authored by NFH. 

1. The RetailCommitment object from NFH is based on the older model of lineId (of a Contract). With 2.0 of Beckn, the base Commitment object already references the offer and resources that are being committed. So the lineId,resourceId,offerId tuple is already enforced in the base Commitment. IONTradeComitment has been modified to directly bring in the attributes required from RetailCommitment. 
2. The NFH Address is not customizable. It has some fields and it is closed (additionalProperties:false). We have added IONAddress with both Address attributes and Indonesia specific address attributes.
3. NFH does not currently have a participant extension object. We created a generic participant object in IONParticipant. 
4. In order to indicate the Provider location that will be fulfilling, we need to refer to locations. However NFH locations do not have an ID. So we use our own IdentifiableLocation object and add a new array called providerLocations that will have details including the id. This id can be cross refrenced (e.g. fulfillingLocationId)

## Future improvements
In future releases we will continue to improve the base spec. Due to time contraint, we have purposefully skipped a couple of them listed below. 

1. In release2, we plan to close all the base objects that have Attributes property (e.g. Resource, Offer, Commitment etc). The style guide recommends it. Having these objects open, introduces silent errors.
2. In release2, we plan to make certain essential properties as required. 

## Changes that need to be made.

1. Configure ONIX to use our ion-beckn.yaml and ion-additional.yaml. In the BAP and BPP config file (e.g. local-simple-bap.yaml and local-simple-bpp.yaml), wherever schema check is enabled, add the following configuration.

```
schemaValidator:
  id: schemav2validator
  config:
    type: url
    location: https://schema.ion.id/release1/schema/core/api/v2.0.0/ion-beckn.yaml
    auxiliaryTypes: "url"
    auxiliaryLocations: "https://schema.ion.id/release1/schema/core/api/v2.0.0/ion-additional.yaml"
```

2. Use the error property in the on_xxx action messages to return business errors.
3. If you are using the legacy structure of Commitment (lineId etc,), use the new structure.
4. See if your payload uses any of the extended objects listed above (IONTradeCommitment, IONAddress, IONTradeParticipant, IONTradeProvider, TrackRequest) and update as appropriate.

## Conclusion
We have a copy of beckn.yaml in our repo called ion-beckn.yaml. Use this file as the primary OpenAPI validator. Some NFH Schema objects have issues, for which we have a alternative in corresponding ION extension objects. 