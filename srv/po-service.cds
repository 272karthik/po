using {po} from '../db/schema';

@odata.draft.enabled
@requires: 'authenticated-user'
service PurchaseOrderService @(path: '/purchase-order') {

    // ============================================================
    // VIRTUAL ENTITY – Approved PRs fetched from the external API
    // ============================================================
    @readonly
    entity ApprovedPurchaseRequests {
        key requestNumber : String(20);
            requesterName : String(100);
            department    : String(100);
            requestDate   : Date;
            currency      : String(3);
            totalAmount   : Decimal(15, 2);
            status        : String(20);
    }

    // ============================================================
    // MAIN ENTITY
    // ============================================================
    entity PurchaseOrders          as projection on po.PurchaseOrders
        actions {
            action submit()                                     returns PurchaseOrders;
            action approve(comments: String(1000) default null) returns PurchaseOrders;
            action reject(comments: String(1000))               returns PurchaseOrders;
            action cancel()                                     returns PurchaseOrders;
            action rework()                                     returns PurchaseOrders; // Rule 24
        };

    // ============================================================
    // CHILD ENTITY
    // ============================================================
    entity PurchaseOrderItems      as projection on po.PurchaseOrderItems;

    // ============================================================
    // MASTER DATA
    // ============================================================
    entity Vendors                 as projection on po.Vendors;
    entity CompanyCodes            as projection on po.CompanyCodes;
    entity PurchasingOrganizations as projection on po.PurchasingOrganizations;
    entity PurchasingGroups        as projection on po.PurchasingGroups;
    entity Currencies              as projection on po.Currencies;

    // ============================================================
    // CONFIGURATION (Rule 27)
    // ============================================================
    entity ApprovalMatrix          as projection on po.ApprovalMatrix;

    // ============================================================
    // AUDIT & LOGGING (Rules 29, 30, 31)
    // ============================================================
    entity POStatusHistory         as projection on po.POStatusHistory;
    entity PONotifications         as projection on po.PONotifications;
    entity PurchaseOrderAuditLogs  as projection on po.PurchaseOrderAuditLogs;
}
