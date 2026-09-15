@cds.external
service PurchaseRequestService {
    // This is just the shape of the remote service
    // We do NOT reference any local entity – only the OData API
    entity PurchaseRequest {
        key ID                : UUID;
            requestNumber     : String(20);
            requesterName     : String(100);
            department        : String(20);
            requestDate       : Date;
            currency          : String(3);
            totalAmount       : Decimal(15, 2);
            status            : String(20);
            approvalComments  : String(500);
            rejectionComments : String(500);
    }

    entity PurchaseRequestItem {
        key ID             : UUID;
            parent_ID      : UUID;
            materialNumber : String(50);
            description    : String(500);
            quantity       : Integer;
            unitPrice      : Decimal(15, 2);
            grossAmount    : Decimal(15, 2);
    }
}
