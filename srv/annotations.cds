using PurchaseOrderService from './po-service';

// ================================================================
// PURCHASE ORDERS – Main Entity
// ================================================================

annotate PurchaseOrderService.PurchaseOrders with @(

    // ----- Header Info -----
    UI.HeaderInfo                       : {
        TypeName      : 'Purchase Order',
        TypeNamePlural: 'Purchase Orders',
        Title         : {
            $Type: 'UI.DataField',
            Label: 'PO Number',
            Value: poNumber
        },
        Description   : {
            $Type: 'UI.DataField',
            Label: 'Vendor',
            Value: vendorName
        }
    },

    // ----- List Columns -----
    UI.LineItem                         : [
        {
            $Type: 'UI.DataField',
            Value: poNumber,
            Label: 'PO Number'
        },
        {
            $Type: 'UI.DataField',
            Value: prNumber,
            Label: 'PR Number'
        },
        {
            $Type: 'UI.DataField',
            Value: vendorName,
            Label: 'Vendor'
        },
        {
            $Type: 'UI.DataField',
            Value: poDate,
            Label: 'PO Date'
        },
        {
            $Type: 'UI.DataField',
            Value: validFrom,
            Label: 'Valid From'
        },
        {
            $Type: 'UI.DataField',
            Value: validTo,
            Label: 'Valid To'
        },
        {
            $Type: 'UI.DataField',
            Value: totalGrossAmount,
            Label: 'Total Amount'
        },
        {
            $Type: 'UI.DataField',
            Value: status,
            Label: 'Status'
        }
    ],

    // ----- Object Page Tabs -----
    UI.Facets                           : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'POInformationFacet',
            Label : 'PO Information',
            Target: '@UI.FieldGroup#POInformation'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'VendorInformationFacet',
            Label : 'Vendor Information',
            Target: '@UI.FieldGroup#VendorInformation'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'PurchasingInformationFacet',
            Label : 'Purchasing Information',
            Target: '@UI.FieldGroup#PurchasingInformation'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'ItemsFacet',
            Label : 'Purchase Order Items',
            Target: 'items/@UI.LineItem'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'NotificationsFacet',
            Label : 'Notifications',
            Target: 'notifications/@UI.LineItem'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'HistoryFacet',
            Label : 'Status History',
            Target: 'history/@UI.LineItem'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'AuditLogFacet',
            Label : 'Audit Log',
            Target: 'auditLogs/@UI.LineItem'
        }
    ],

    // ----- Field Groups -----
    UI.FieldGroup #POInformation        : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: poNumber,
                Label: 'PO Number'
            },
            {
                $Type: 'UI.DataField',
                Value: prNumber,
                Label: 'PR Number'
            },
            {
                $Type: 'UI.DataField',
                Value: poDate,
                Label: 'PO Date'
            },
            {
                $Type: 'UI.DataField',
                Value: validFrom,
                Label: 'Valid From'
            },
            {
                $Type: 'UI.DataField',
                Value: validTo,
                Label: 'Valid To'
            },
            {
                $Type: 'UI.DataField',
                Value: status,
                Label: 'Status'
            },
            {
                $Type: 'UI.DataField',
                Value: requesterName,
                Label: 'Requester'
            },
            {
                $Type: 'UI.DataField',
                Value: approver,
                Label: 'Approver'
            },
            {
                $Type: 'UI.DataField',
                Value: approverLevel,
                Label: 'Approver Level'
            },
            {
                $Type: 'UI.DataField',
                Value: approvalComments,
                Label: 'Approval Comments'
            },
            {
                $Type: 'UI.DataField',
                Value: rejectionComments,
                Label: 'Rejection Comments'
            }
        ]
    },

    UI.FieldGroup #VendorInformation    : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: vendor,
                Label: 'Vendor'
            },
            {
                $Type: 'UI.DataField',
                Value: vendorName,
                Label: 'Vendor Name'
            },
            {
                $Type: 'UI.DataField',
                Value: vendorAddress,
                Label: 'Vendor Address'
            },
            {
                $Type: 'UI.DataField',
                Value: currency,
                Label: 'Currency'
            }
        ]
    },

    UI.FieldGroup #PurchasingInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: companyCode,
                Label: 'Company Code'
            },
            {
                $Type: 'UI.DataField',
                Value: purchasingOrg,
                Label: 'Purchasing Organization'
            },
            {
                $Type: 'UI.DataField',
                Value: purchasingGroup,
                Label: 'Purchasing Group'
            },
            {
                $Type: 'UI.DataField',
                Value: buyer,
                Label: 'Buyer'
            },
            {
                $Type: 'UI.DataField',
                Value: paymentTerms,
                Label: 'Payment Terms'
            },
            {
                $Type: 'UI.DataField',
                Value: deliveryLocation,
                Label: 'Delivery Location'
            },
            {
                $Type: 'UI.DataField',
                Value: notes,
                Label: 'Notes'
            }
        ]
    },

    // ----- Action Buttons -----
    UI.Identification                   : [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.submit',
            Label : 'Submit'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.approve',
            Label : 'Approve'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.rejectPO',
            Label : 'Reject'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.cancel',
            Label : 'Cancel'
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.rework',
            Label : 'Rework'
        }
    ]
);


// ================================================================
// PURCHASE ORDER ITEMS
// ================================================================

annotate PurchaseOrderService.PurchaseOrderItems with @(

    UI.LineItem                     : [
        {
            $Type: 'UI.DataField',
            Value: poItemNumber,
            Label: 'Item'
        },
        {
            $Type: 'UI.DataField',
            Value: prItemNumber,
            Label: 'PR Item'
        },
        {
            $Type: 'UI.DataField',
            Value: materialNumber,
            Label: 'Material Number'
        },
        {
            $Type: 'UI.DataField',
            Value: description,
            Label: 'Description'
        },
        {
            $Type: 'UI.DataField',
            Value: quantity,
            Label: 'Quantity'
        },
        {
            $Type: 'UI.DataField',
            Value: unit,
            Label: 'Unit'
        },
        {
            $Type: 'UI.DataField',
            Value: unitPrice,
            Label: 'Unit Price'
        },
        {
            $Type: 'UI.DataField',
            Value: netAmount,
            Label: 'Net Amount'
        },
        {
            $Type: 'UI.DataField',
            Value: taxRate,
            Label: 'Tax %'
        },
        {
            $Type: 'UI.DataField',
            Value: taxAmount,
            Label: 'Tax Amount'
        },
        {
            $Type: 'UI.DataField',
            Value: grossAmount,
            Label: 'Gross Amount'
        },
        {
            $Type: 'UI.DataField',
            Value: deliveryDate,
            Label: 'Delivery Date'
        }
    ],

    UI.HeaderInfo                   : {
        TypeName      : 'Purchase Order Item',
        TypeNamePlural: 'Purchase Order Items',
        Title         : {
            $Type: 'UI.DataField',
            Value: description,
            Label: 'Description'
        },
        Description   : {
            $Type: 'UI.DataField',
            Value: materialNumber,
            Label: 'Material Number'
        }
    },

    UI.Facets                       : [
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'ItemInformationFacet',
            Label : 'Item Information',
            Target: '@UI.FieldGroup#ItemInformation'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'AmountInformationFacet',
            Label : 'Amount Information',
            Target: '@UI.FieldGroup#AmountInformation'
        },
        {
            $Type : 'UI.ReferenceFacet',
            ID    : 'ItemDeliveryFacet',
            Label : 'Delivery Information',
            Target: '@UI.FieldGroup#ItemDelivery'
        }
    ],

    UI.FieldGroup #ItemInformation  : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: poItemNumber,
                Label: 'Item Number'
            },
            {
                $Type: 'UI.DataField',
                Value: prItemNumber,
                Label: 'PR Item Number'
            },
            {
                $Type: 'UI.DataField',
                Value: materialNumber,
                Label: 'Material Number'
            },
            {
                $Type: 'UI.DataField',
                Value: description,
                Label: 'Description'
            },
            {
                $Type: 'UI.DataField',
                Value: quantity,
                Label: 'Quantity'
            },
            {
                $Type: 'UI.DataField',
                Value: unit,
                Label: 'Unit'
            }
        ]
    },

    UI.FieldGroup #AmountInformation: {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: unitPrice,
                Label: 'Unit Price'
            },
            {
                $Type: 'UI.DataField',
                Value: netAmount,
                Label: 'Net Amount'
            },
            {
                $Type: 'UI.DataField',
                Value: taxRate,
                Label: 'Tax %'
            },
            {
                $Type: 'UI.DataField',
                Value: taxAmount,
                Label: 'Tax Amount'
            },
            {
                $Type: 'UI.DataField',
                Value: grossAmount,
                Label: 'Gross Amount'
            }
        ]
    },

    UI.FieldGroup #ItemDelivery     : {
        $Type: 'UI.FieldGroupType',
        Data : [
            {
                $Type: 'UI.DataField',
                Value: deliveryDate,
                Label: 'Delivery Date'
            },
            {
                $Type: 'UI.DataField',
                Value: deliveryLocation,
                Label: 'Delivery Location'
            },
            {
                $Type: 'UI.DataField',
                Value: itemStatus,
                Label: 'Item Status'
            },
            {
                $Type: 'UI.DataField',
                Value: acceptedQty,
                Label: 'Accepted Quantity'
            },
            {
                $Type: 'UI.DataField',
                Value: remainingQty,
                Label: 'Remaining Quantity'
            }
        ]
    }
);


// ================================================================
// READ-ONLY FIELDS
// ================================================================

annotate PurchaseOrderService.PurchaseOrders with {
    poNumber         @Common.FieldControl: #ReadOnly;
    totalNetAmount   @Common.FieldControl: #ReadOnly;
    totalTaxAmount   @Common.FieldControl: #ReadOnly;
    totalGrossAmount @Common.FieldControl: #ReadOnly;
    status           @Common.FieldControl: #ReadOnly;
    approver         @Common.FieldControl: #ReadOnly;
    approverLevel    @Common.FieldControl: #ReadOnly;
    requesterName    @Common.FieldControl: #ReadOnly;
};

annotate PurchaseOrderService.PurchaseOrderItems with {
    poItemNumber @Common.FieldControl: #ReadOnly;
    netAmount    @Common.FieldControl: #ReadOnly;
    taxAmount    @Common.FieldControl: #ReadOnly;
    grossAmount  @Common.FieldControl: #ReadOnly;
    remainingQty @Common.FieldControl: #ReadOnly;
};


// ================================================================
// VALUE LISTS (Dropdowns)
// ================================================================

// Vendor
annotate PurchaseOrderService.PurchaseOrders with {
    vendor @Common.ValueListWithFixedValues: true
           @Common.ValueList               : {
        Label         : 'Vendor',
        CollectionPath: 'Vendors',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: vendor_ID,
                ValueListProperty: 'vendorId'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'name'
            }
        ]
    };
};

// Company Code
annotate PurchaseOrderService.PurchaseOrders with {
    companyCode @Common.ValueListWithFixedValues: true
                @Common.ValueList               : {
        Label         : 'Company Code',
        CollectionPath: 'CompanyCodes',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: companyCode_ID,
                ValueListProperty: 'companyCode'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'companyName'
            }
        ]
    };
};

// Currency
annotate PurchaseOrderService.PurchaseOrders with {
    currency @Common.ValueListWithFixedValues: true
             @Common.ValueList               : {
        Label         : 'Currency',
        CollectionPath: 'Currencies',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: currency_ID,
                ValueListProperty: 'code'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'name'
            }
        ]
    };
};

// Purchasing Organization
annotate PurchaseOrderService.PurchaseOrders with {
    purchasingOrg @Common.ValueListWithFixedValues: true
                  @Common.ValueList               : {
        Label         : 'Purchasing Organization',
        CollectionPath: 'PurchasingOrganizations',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: purchasingOrg_ID,
                ValueListProperty: 'purchasingOrg'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'purchasingOrgName'
            }
        ]
    };
};

// Purchasing Group
annotate PurchaseOrderService.PurchaseOrders with {
    purchasingGroup @Common.ValueListWithFixedValues: true
                    @Common.ValueList               : {
        Label         : 'Purchasing Group',
        CollectionPath: 'PurchasingGroups',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: purchasingGroup_ID,
                ValueListProperty: 'purchasingGroup'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'purchasingGroupName'
            }
        ]
    };
};

// PR Number – dropdown from ApprovedPurchaseRequests
annotate PurchaseOrderService.PurchaseOrders with {
    prNumber @Common.ValueList: {
        Label         : 'Approved Purchase Requests',
        CollectionPath: 'ApprovedPurchaseRequests',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: prNumber,
                ValueListProperty: 'requestNumber'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'requesterName'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'department'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'requestDate'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'currency'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'totalAmount'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'status'
            }
        ]
    };
};


// ================================================================
// VIRTUAL ENTITY – Approved Purchase Requests
// ================================================================

annotate PurchaseOrderService.ApprovedPurchaseRequests with @(
    UI.LineItem  : [
        {
            $Type: 'UI.DataField',
            Value: requestNumber,
            Label: 'PR Number'
        },
        {
            $Type: 'UI.DataField',
            Value: requesterName,
            Label: 'Requester'
        },
        {
            $Type: 'UI.DataField',
            Value: department,
            Label: 'Department'
        },
        {
            $Type: 'UI.DataField',
            Value: requestDate,
            Label: 'Request Date'
        },
        {
            $Type: 'UI.DataField',
            Value: currency,
            Label: 'Currency'
        },
        {
            $Type: 'UI.DataField',
            Value: totalAmount,
            Label: 'Total Amount'
        },
        {
            $Type: 'UI.DataField',
            Value: status,
            Label: 'Status'
        }
    ],
    UI.HeaderInfo: {
        TypeName      : 'Approved Purchase Request',
        TypeNamePlural: 'Approved Purchase Requests',
        Title         : {
            $Type: 'UI.DataField',
            Value: requestNumber,
            Label: 'PR Number'
        },
        Description   : {
            $Type: 'UI.DataField',
            Value: requesterName,
            Label: 'Requester'
        }
    }
);


// ================================================================
// PO STATUS HISTORY
// ================================================================

annotate PurchaseOrderService.POStatusHistory with @UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: poNumber,
        Label: 'PO Number'
    },
    {
        $Type: 'UI.DataField',
        Value: oldStatus,
        Label: 'Old Status'
    },
    {
        $Type: 'UI.DataField',
        Value: newStatus,
        Label: 'New Status'
    },
    {
        $Type: 'UI.DataField',
        Value: user,
        Label: 'User'
    },
    {
        $Type: 'UI.DataField',
        Value: comments,
        Label: 'Comments'
    },
    {
        $Type: 'UI.DataField',
        Value: timestamp,
        Label: 'Timestamp'
    }
];


// ================================================================
// PO NOTIFICATIONS
// ================================================================

annotate PurchaseOrderService.PONotifications with @UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: poNumber,
        Label: 'PO Number'
    },
    {
        $Type: 'UI.DataField',
        Value: type,
        Label: 'Type'
    },
    {
        $Type: 'UI.DataField',
        Value: message,
        Label: 'Message'
    },
    {
        $Type: 'UI.DataField',
        Value: recipient,
        Label: 'Recipient'
    },
    {
        $Type: 'UI.DataField',
        Value: readStatus,
        Label: 'Read'
    }
];


// ================================================================
// PO AUDIT LOGS
// ================================================================

annotate PurchaseOrderService.PurchaseOrderAuditLogs with @UI.LineItem: [
    {
        $Type: 'UI.DataField',
        Value: action,
        Label: 'Action'
    },
    {
        $Type: 'UI.DataField',
        Value: oldStatus,
        Label: 'Old Status'
    },
    {
        $Type: 'UI.DataField',
        Value: newStatus,
        Label: 'New Status'
    },
    {
        $Type: 'UI.DataField',
        Value: performedBy,
        Label: 'Performed By'
    },
    {
        $Type: 'UI.DataField',
        Value: performedRole,
        Label: 'Role'
    },
    {
        $Type: 'UI.DataField',
        Value: remarks,
        Label: 'Remarks'
    },
    {
        $Type: 'UI.DataField',
        Value: eventTime,
        Label: 'Event Time'
    }
];

annotate PurchaseOrderService.PurchaseOrderAuditLogs with {
    action        @Common.Label: 'Action';
    oldStatus     @Common.Label: 'Old Status';
    newStatus     @Common.Label: 'New Status';
    performedBy   @Common.Label: 'Performed By';
    performedRole @Common.Label: 'Role';
    remarks       @Common.Label: 'Remarks';
    eventTime     @Common.Label: 'Event Time';
};
