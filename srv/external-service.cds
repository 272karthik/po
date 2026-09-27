@cds.external
service PRService {
    entity PurchaseRequest {
        key ID            : UUID;
            requestNumber : String(20);
            requesterName : String(100);
            department    : String(20);
            requestDate   : Date;
            currency      : String(3);
            totalAmount   : Decimal(15, 2);
            status        : String(20);
    }

    entity PurchaseRequestItem {
        key ID            : UUID;
            parent_ID     : UUID;
            materialNumber: String(50);
            description   : String(500);
            quantity      : Integer;
            unitPrice     : Decimal(15, 2);
            grossAmount   : Decimal(15, 2);
    }
}