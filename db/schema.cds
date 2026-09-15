namespace po;

using {
    cuid,
    managed
} from '@sap/cds/common';

// ================================================================
// ENUMS
// ================================================================

type POStatus : String(20) enum {
    Draft = 'Draft';
    Submitted = 'Submitted';
    Approved = 'Approved';
    Rejected = 'Rejected';
    Cancelled = 'Cancelled';
    Issued = 'Issued';
    Completed = 'Completed';
}
// ================================================================
// MASTER DATA
// ================================================================

entity Vendors {
    key vendorId : String(20);
        name     : String(100);
        address  : String(255);
        contact  : String(100);
        status   : String(20) default 'Active';
}

entity CompanyCodes {
    key companyCode : String(10);
        companyName : String(100);
}

entity PurchasingOrganizations {
    key purchasingOrg     : String(10);
        purchasingOrgName : String(100);
}

entity PurchasingGroups {
    key purchasingGroup     : String(10);
        purchasingGroupName : String(100);
}

entity Currencies {
    key currencyCode : String(3);
        currencyName : String(50);
}

entity ApprovalMatrix : cuid {
    minAmount    : Decimal(15, 2);
    maxAmount    : Decimal(15, 2);
    approverRole : String(50);
    active       : Boolean default true;
}

// ================================================================
// PURCHASE ORDER
// ================================================================

entity PurchaseOrders : cuid, managed {

    // ----- Header -----
    poNumber            : String(20); // Auto-generated
    prNumber            : String(20); // Reference to PR (from API)
    vendor              : Association to Vendors;
    vendorName          : String(100); // Denormalized
    vendorAddress       : String(255); // Denormalized
    requesterName       : String(100); // Fetched from PR API
    department          : String(20); // Fetched from PR API
    poDate              : Date;
    validFrom           : Date;
    validTo             : Date;
    currency            : Association to Currencies;

    // ----- Amounts -----
    totalNetAmount      : Decimal(15, 2) @Core.Computed;
    totalTaxAmount      : Decimal(15, 2) @Core.Computed;
    totalGrossAmount    : Decimal(15, 2) @Core.Computed;

    // ----- Status -----
    status              : POStatus default 'Draft';

    // ----- Procurement -----
    companyCode         : Association to CompanyCodes;
    purchasingOrg       : Association to PurchasingOrganizations;
    purchasingGroup     : Association to PurchasingGroups;
    buyer               : String(100);
    paymentTerms        : String(100);
    deliveryLocation    : String(255);
    notes               : String(500);

    // ----- Approver -----
    approver            : String(100)    @Core.Computed;
    approverLevel       : String(20)     @Core.Computed;
    approvalComments    : String(500);
    rejectionComments   : String(500);


    virtual hideSubmit  : Boolean;
    virtual hideApprove : Boolean;
    virtual hideReject  : Boolean;
    virtual canCancel   : Boolean;
    virtual canRework   : Boolean;

    // ----- Compositions -----
    items               : Composition of many PurchaseOrderItems
                              on items.parent = $self;
    auditLogs           : Composition of many PurchaseOrderAuditLogs
                              on auditLogs.purchaseOrder = $self;
    history             : Composition of many POStatusHistory
                              on history.purchaseOrder = $self;
    notifications       : Composition of many PONotifications
                              on notifications.purchaseOrder = $self;
}

// ================================================================
// PO ITEMS
// ================================================================

entity PurchaseOrderItems : cuid {
    parent           : Association to PurchaseOrders;
    poItemNumber     : Integer;
    prItemNumber     : String(10); // PR item number from API
    materialNumber   : String(50);
    description      : String(500);
    quantity         : Decimal(15, 2);
    unit             : String(10);
    unitPrice        : Decimal(15, 2);

    taxRate          : Decimal(5, 2) default 18;
    netAmount        : Decimal(15, 2) @Core.Computed;
    taxAmount        : Decimal(15, 2) @Core.Computed;
    grossAmount      : Decimal(15, 2) @Core.Computed;

    deliveryDate     : Date;
    deliveryLocation : String(255);
    itemStatus       : String(20) default 'Open';

    acceptedQty      : Decimal(15, 2) default 0;
    remainingQty     : Decimal(15, 2) @Core.Computed;
}

// ================================================================
// SUPPORTING ENTITIES
// ================================================================

entity POStatusHistory : cuid {
    purchaseOrder : Association to PurchaseOrders;
    poNumber      : String(20);
    oldStatus     : String(20);
    newStatus     : String(20);
    user          : String(100);
    comments      : String(500);
    timestamp     : Timestamp;
}

entity PONotifications : cuid, managed {
    purchaseOrder : Association to PurchaseOrders;
    poNumber      : String(20);
    type          : String(20);
    message       : String(255);
    recipient     : String(100);
    readStatus    : Boolean default false;
}

entity PurchaseOrderAuditLogs : cuid, managed {
    purchaseOrder : Association to PurchaseOrders;
    poNumber      : String(20);
    prNumber      : String(20);
    action        : String(30);
    oldStatus     : String(20);
    newStatus     : String(20);
    performedBy   : String(100);
    performedRole : String(50);
    remarks       : String(500);
    eventTime     : Timestamp;
}
