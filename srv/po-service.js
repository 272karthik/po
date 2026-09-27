const cds = require('@sap/cds');

module.exports = cds.service.impl(async function () {
    const {
        PurchaseOrders,
        PurchaseOrderItems,
        POStatusHistory,
        PONotifications,
        PurchaseOrderAuditLogs
    } = this.entities;

    // ================================================================
    // RULE 35: Connect to the external PR service (OData API)
    // ================================================================
    const prService = await cds.connect.to('PRService');

    // ================================================================
    // HELPER FUNCTIONS
    // ================================================================

    // RULE 32: Get user role for role-based access
    function getUserRole(req) {
        if (!req?.user) return 'Employee';
        if (req.user.is('Director')) return 'Director';
        if (req.user.is('SeniorManager')) return 'Senior Manager';
        if (req.user.is('Manager')) return 'Manager';
        return 'Employee';
    }

    // Helper: Extract PO ID from request (works for actions and entity ops)
    function getPOId(req) {
        return req.params?.[0]?.ID || req.data?.ID || req.data?.id;
    }

    // RULE 11 + RULE 12: Calculate item amounts (Net, Tax 18%, Gross)
    function calculateItem(item) {
        const quantity = Number(item.quantity || 0);
        const unitPrice = Number(item.unitPrice || 0);
        // RULE 12: Tax rate configurable (default 18%)
        const taxPercent = Number(item.taxRate ?? item.taxPercent ?? 18);

        const netAmount = quantity * unitPrice;                    // RULE 11
        const taxAmount = netAmount * (taxPercent / 100);          // RULE 12
        const grossAmount = netAmount + taxAmount;                   // RULE 11

        item.netAmount = Number(netAmount.toFixed(2));
        item.taxAmount = Number(taxAmount.toFixed(2));
        item.grossAmount = Number(grossAmount.toFixed(2));
        return item;
    }

    // RULE 11: Recalculate PO header totals from all items
    async function recalculatePOTotal(poId) {
        if (!poId) return 0;
        const items = await SELECT.from(PurchaseOrderItems).where({ parent_ID: poId });
        let net = 0, tax = 0, gross = 0;
        for (const it of items) {
            calculateItem(it);
            net += Number(it.netAmount);
            tax += Number(it.taxAmount);
            gross += Number(it.grossAmount);
        }
        await UPDATE(PurchaseOrders, poId).with({
            totalNetAmount: Number(net.toFixed(2)),
            totalTaxAmount: Number(tax.toFixed(2)),
            totalGrossAmount: Number(gross.toFixed(2))
        });
        return gross;
    }

    // RULE 30: Create status history entry
    async function createHistory(poId, oldStatus, newStatus, user, comments) {
        const po = await SELECT.one.from(PurchaseOrders).where({ ID: poId });
        if (!po) return;
        await INSERT.into(POStatusHistory).entries({
            purchaseOrder_ID: poId,
            poNumber: po.poNumber,
            oldStatus: oldStatus,
            newStatus: newStatus,
            user: user || 'SYSTEM',
            comments: comments || '',
            timestamp: new Date()
        });
    }

    // RULE 29: Create notification
    async function createNotification(poId, type, recipient) {
        const po = await SELECT.one.from(PurchaseOrders).where({ ID: poId });
        if (!po) return;
        let message = '';
        switch (type) {
            case 'Submitted': message = `PO ${po.poNumber} has been submitted for approval.`; break;
            case 'Approved': message = `PO ${po.poNumber} has been approved.`; break;
            case 'Rejected': message = `PO ${po.poNumber} has been rejected.`; break;
            case 'Cancelled': message = `PO ${po.poNumber} has been cancelled.`; break;
            case 'Issued': message = `PO ${po.poNumber} has been issued.`; break;
            case 'Completed': message = `PO ${po.poNumber} has been completed.`; break;
        }
        await INSERT.into(PONotifications).entries({
            purchaseOrder_ID: poId,
            poNumber: po.poNumber,
            type: type,
            message: message,
            recipient: recipient || 'SYSTEM',
            readStatus: false
        });
    }

    // RULE 31: Create audit log entry
    async function createAuditLog(req, poId, action, oldStatus, newStatus, remarks) {
        const po = await SELECT.one.from(PurchaseOrders).where({ ID: poId });
        if (!po) return;
        await INSERT.into(PurchaseOrderAuditLogs).entries({
            purchaseOrder_ID: poId,
            poNumber: po.poNumber,
            prNumber: po.prNumber,
            action: action,
            oldStatus: oldStatus,
            newStatus: newStatus,
            performedBy: req?.user?.id || 'SYSTEM',
            performedRole: getUserRole(req),
            remarks: remarks || '',
            eventTime: new Date()
        });
    }

    // ================================================================
    // RULE 35 + 36: Virtual entity – Fetch Approved PRs from PR API
    // ================================================================
    this.on('READ', 'ApprovedPurchaseRequests', async (req) => {
        try {
            console.log('=== Fetching approved PRs ===');

            const prs = await prService.run(
                SELECT.from('PRService.PurchaseRequest').where({ status: 'Approved' })
            );

            console.log('Fetched', prs.length, 'PRs');

            return prs.map(pr => ({
                requestNumber: pr.requestNumber,
                requesterName: pr.requesterName,
                department: pr.department || pr.department_code,
                requestDate: pr.requestDate,
                currency: pr.currency || pr.currency_code,
                totalAmount: pr.totalAmount,
                status: pr.status
            }));
        } catch (err) {
            console.error('=== FULL ERROR ===');
            console.error('Message:', err.message);
            console.error('Code:', err.code);
            console.error('Status:', err.status);
            console.error('Stack:', err.stack);
            return req.reject(502, `Unable to fetch PRs: ${err.message}`);
        }
    });

    // ================================================================
    // BEFORE HANDLERS – HEADER
    // ================================================================

    // RULE 4: Auto-generate PO Number (PO-YYYY-000001) + Default status
    this.before('CREATE', PurchaseOrders, async (req) => {
        const year = new Date().getFullYear();
        const last = await SELECT.one.from(PurchaseOrders)
            .where({ poNumber: { like: `PO-${year}-%` } })
            .orderBy({ poNumber: 'desc' });
        let next = 1;
        if (last && last.poNumber) {
            const parts = last.poNumber.split('-');
            if (parts.length === 3 && !isNaN(parseInt(parts[2]))) {
                next = parseInt(parts[2]) + 1;
            }
        }
        req.data.poNumber = `PO-${year}-${String(next).padStart(6, '0')}`;
        req.data.status = 'Draft';   // RULE 5: default status
    });

    // RULE 1: Only Approved PR Can Create PO
    // RULE 3: PR Reference Mandatory
    // RULE 35: Fetch PR data via API
    this.before('CREATE', PurchaseOrders, async (req) => {
        const prNumber = req.data.prNumber;
        if (!prNumber) {
            return req.error(400, 'Purchase Request reference is mandatory.');  // RULE 3
        }
        const pr = await prService.run(
            SELECT.one.from('PurchaseRequestService.PurchaseRequest')
                .where({ requestNumber: prNumber, status: 'Approved' })
        );
        if (!pr) {
            return req.error(400, 'Purchase Order can only be created from an approved Purchase Request.');  // RULE 1
        }
        // Auto-fill fields from PR (Rule 35)
        req.data.requesterName = pr.requesterName;
        req.data.department = pr.department_code || pr.department;
        req.data.currency_code = pr.currency_code || pr.currency;
    });

    // RULE 13: Vendor Mandatory
    // RULE 14: Currency Mandatory
    // RULE 15: PO Validity (Valid From <= Valid To)
    // RULE 16 (Header): Total Amount cannot be negative
    this.before(['CREATE', 'UPDATE'], PurchaseOrders, async (req) => {
        // RULE 13
        if (req.data.vendor_ID === '' || req.data.vendor_ID === null) {
            return req.error(400, 'Vendor is mandatory for creating a Purchase Order.');
        }
        // RULE 14
        if (req.data.currency_code !== undefined &&
            (!req.data.currency_code || !String(req.data.currency_code).trim())) {
            return req.error(400, 'Currency is mandatory.');
        }
        // RULE 15
        if (req.data.validFrom && req.data.validTo && req.data.validFrom > req.data.validTo) {
            return req.error(400, 'Valid From date cannot be greater than Valid To date.');
        }
        // Header total cannot be negative
        if (req.data.totalAmount !== undefined && Number(req.data.totalAmount) < 0) {
            return req.error(400, 'Total Amount cannot be negative.');
        }
    });

    // RULE 19: Only Draft PO Can Be Edited
    // RULE 26: Immutable Records (Approved/Issued/Completed/Cancelled cannot be modified)
    this.before(['UPDATE', 'DELETE'], PurchaseOrders, async (req) => {
        const po = await SELECT.one.from(PurchaseOrders).where({ ID: req.data.ID });
        if (po && po.status !== 'Draft') {
            return req.error(400, `Only Draft Purchase Orders can be edited. Current: ${po.status}`);
        }
    });

    // ================================================================
    // BEFORE HANDLERS – ITEMS
    // ================================================================

    // RULE 2:  Multiple PO Items from PR
    // RULE 8:  Quantity > 0
    // RULE 10: Unit Price > 0
    // RULE 11 + 12: Calculate Net/Tax/Gross
    // RULE 16: Delivery Date validation
    // RULE 18: Duplicate Items
    // RULE 19: Only Draft items can be modified
    this.before(['CREATE', 'UPDATE'], PurchaseOrderItems, async (req) => {
        const item = req.data;

        // RULE 8
        if (Number(item.quantity) <= 0) {
            return req.error(400, 'PO quantity must be greater than zero.');
        }
        // RULE 10
        if (Number(item.unitPrice) <= 0) {
            return req.error(400, 'Unit Price must be greater than zero.');
        }
        // Description min 3 chars
        if (!item.description || item.description.trim().length < 3) {
            return req.error(400, 'Description must contain at least 3 characters.');
        }
        // RULE 12: Tax % must be between 0 and 100
        if (item.taxPercent !== undefined &&
            (Number(item.taxPercent) < 0 || Number(item.taxPercent) > 100)) {
            return req.error(400, 'Tax percentage must be between 0 and 100.');
        }

        // RULE 12: Fixed tax rate at 18%
        item.taxPercent = 18;

        // RULE 11 + 12: Calculate Net, Tax, Gross
        calculateItem(item);

        // Parent checks
        let parentId = item.parent_ID;
        if (!parentId && item.ID) {
            const existing = await SELECT.one.from(PurchaseOrderItems).where({ ID: item.ID });
            if (existing) parentId = existing.parent_ID;
        }

        if (parentId) {
            const po = await SELECT.one.from(PurchaseOrders).where({ ID: parentId });
            if (!po) return req.error(404, 'Purchase Order not found.');

            // RULE 19: Only Draft items can be modified
            if (po.status !== 'Draft') {
                return req.error(400, 'Items can only be modified in Draft status.');
            }

            // RULE 18: Duplicate Material Number check
            if (item.materialNumber) {
                const existing = await SELECT.one.from(PurchaseOrderItems)
                    .where({ parent_ID: parentId, materialNumber: item.materialNumber });
                if (existing && existing.ID !== item.ID) {
                    return req.error(400, 'Duplicate Material Number is not allowed in this Purchase Order.');
                }
            }

            // RULE 16: Delivery Date >= PO Date
            if (item.deliveryDate && po.poDate) {
                if (new Date(item.deliveryDate) < new Date(po.poDate)) {
                    return req.error(400, 'Delivery date cannot be earlier than the PO date.');
                }
            }
        }
    });

    // RULE 17: Max 20 Items per PO
    this.before('CREATE', PurchaseOrderItems, async (req) => {
        const parentId = req.data.parent_ID;
        if (parentId) {
            const count = await SELECT.from(PurchaseOrderItems).where({ parent_ID: parentId }).count();
            if (count >= 20) {
                return req.error(400, 'A Purchase Order cannot contain more than 20 items.');
            }
        }
    });

    // RULE 20: Item Deletion allowed only in Draft
    this.before('DELETE', PurchaseOrderItems, async (req) => {
        const item = await SELECT.one.from(PurchaseOrderItems).where({ ID: req.data.ID });
        if (!item) return;
        const po = await SELECT.one.from(PurchaseOrders).where({ ID: item.parent_ID });
        if (po && po.status !== 'Draft') {
            return req.error(400, 'Items cannot be deleted after submission.');
        }
    });

    // ================================================================
    // AFTER HANDLERS
    // ================================================================

    // RULE 11: Recalculate PO totals after item changes
    this.after(['CREATE', 'UPDATE', 'DELETE'], PurchaseOrderItems, async (data, req) => {
        let parentId = data?.parent_ID || req.data?.parent_ID;
        if (!parentId && (data?.ID || req.data?.ID)) {
            const id = data?.ID || req.data?.ID;
            const item = await SELECT.one.from(PurchaseOrderItems).where({ ID: id });
            if (item) parentId = item.parent_ID;
        }
        if (parentId) await recalculatePOTotal(parentId);
    });

    // RULE 31: Audit log on PO creation
    this.after('CREATE', PurchaseOrders, async (data, req) => {
        await createAuditLog(req, data.ID, 'CREATED', '', 'Draft', 'Purchase Order created');
    });

    // RULE 31: Audit log on PO update
    this.after('UPDATE', PurchaseOrders, async (data, req) => {
        if (!data) return;
        await createAuditLog(req, data.ID, 'UPDATED', data.status, data.status, 'Purchase Order updated');
    });

    // ================================================================
    // CUSTOM ACTIONS
    // ================================================================

    // ----------------------------------------------------------------
    // RULE 21: SUBMIT – Draft → Submitted
    // ----------------------------------------------------------------
    this.on('submit', async (req) => {
        const ID = getPOId(req);
        if (!ID) return req.error(400, 'Purchase Order ID is missing.');

        const po = await SELECT.one.from(PurchaseOrders).where({ ID });
        if (!po) return req.error(404, 'Purchase Order not found.');

        // RULE 5: Only Draft can be submitted
        if (po.status !== 'Draft') {
            return req.error(400, `Only Draft Purchase Orders can be submitted. Current: ${po.status}`);
        }

        // RULE 21: Vendor must exist
        if (!po.vendor_ID) return req.error(400, 'Vendor is mandatory.');

        const items = await SELECT.from(PurchaseOrderItems).where({ parent_ID: ID });

        // RULE 21: At least one item required
        if (!items || items.length === 0) {
            return req.error(400, 'At least one item is required.');
        }

        // RULE 18: Duplicate Material check
        const materials = new Set();
        for (const it of items) {
            if (it.materialNumber && materials.has(it.materialNumber)) {
                return req.error(400, `Duplicate Material Number '${it.materialNumber}' is not allowed.`);
            }
            if (it.materialNumber) materials.add(it.materialNumber);

            // RULE 8, 10: Re-validate each item
            if (Number(it.quantity) <= 0) return req.error(400, 'Quantity must be greater than zero.');
            if (Number(it.unitPrice) <= 0) return req.error(400, 'Unit Price must be greater than zero.');

            // RULE 16: Delivery date validation
            if (it.deliveryDate && po.poDate && new Date(it.deliveryDate) < new Date(po.poDate)) {
                return req.error(400, 'Delivery date cannot be earlier than the PO date.');
            }
        }

        // RULE 11: Recalculate PO total
        await recalculatePOTotal(ID);

        // RULE 5: Change status
        await UPDATE(PurchaseOrders, ID).with({ status: 'Submitted' });

        // RULE 30: History
        await createHistory(ID, 'Draft', 'Submitted', req.user.id, 'Submitted for approval');
        // RULE 29: Notification
        await createNotification(ID, 'Submitted', po.approver);
        // RULE 31: Audit log
        await createAuditLog(req, ID, 'SUBMITTED', 'Draft', 'Submitted', 'Purchase Order submitted');

        return await SELECT.one.from(PurchaseOrders).where({ ID });
    });

    // ----------------------------------------------------------------
    // RULE 22, 27, 28: APPROVE – Submitted → Approved
    // ----------------------------------------------------------------
    this.on('approve', async (req) => {
        const ID = getPOId(req);
        const comments = req.data.comments || '';

        const po = await SELECT.one.from(PurchaseOrders).where({ ID });
        if (!po) return req.error(404, 'Purchase Order not found.');

        // RULE 28: Prevent concurrent approval
        if (po.status !== 'Submitted') {
            return req.error(400, 'Purchase Order already processed by another user.');
        }

        // RULE 27: Role-based approval matrix
        const role = getUserRole(req);
        const amount = Number(po.totalGrossAmount || po.totalAmount || 0);

        if (amount <= 10000 && !['Manager', 'SeniorManager', 'Director', 'Admin'].includes(role)) {
            return req.error(403, 'Only Manager or higher can approve this Purchase Order.');
        }
        if (amount > 10000 && amount <= 50000 && !['SeniorManager', 'Director', 'Admin'].includes(role)) {
            return req.error(403, 'Only Senior Manager or higher can approve this Purchase Order.');
        }
        if (amount > 50000 && !['Director', 'Admin'].includes(role)) {
            return req.error(403, 'Only Director can approve this Purchase Order.');
        }

        // RULE 32: Self-approval prevention
        if (po.requesterName === req.user.id) {
            return req.error(403, 'Requester cannot approve their own Purchase Order.');
        }

        // RULE 22: Change status to Approved
        await UPDATE(PurchaseOrders, ID).with({
            status: 'Approved',
            approvalComments: comments
        });

        await createHistory(ID, 'Submitted', 'Approved', req.user.id, comments);   // RULE 30
        await createNotification(ID, 'Approved', po.requesterName);                 // RULE 29
        await createAuditLog(req, ID, 'APPROVED', 'Submitted', 'Approved', comments); // RULE 31

        return await SELECT.one.from(PurchaseOrders).where({ ID });
    });

    // ----------------------------------------------------------------
    // RULE 23: REJECT – Submitted → Rejected (comments mandatory, min 20)
    // ----------------------------------------------------------------
    this.on('rejectPO', async (req) => {
        const ID = getPOId(req);
        const comments = req.data.comments || req.data.reason || '';

        // RULE 23: Rejection comments mandatory (min 20 chars)
        if (!comments || comments.trim().length < 20) {
            return req.error(400, 'Rejection comments are mandatory and must be at least 20 characters.');
        }

        const po = await SELECT.one.from(PurchaseOrders).where({ ID });
        if (!po) return req.error(404, 'Purchase Order not found.');

        // RULE 5: Only Submitted can be rejected
        if (po.status !== 'Submitted') {
            return req.error(400, `Only Submitted Purchase Orders can be rejected. Current: ${po.status}`);
        }

        // RULE 23: Change status to Rejected
        await UPDATE(PurchaseOrders, ID).with({
            status: 'Rejected',
            rejectionComments: comments
        });

        await createHistory(ID, 'Submitted', 'Rejected', req.user.id, comments);      // RULE 30
        await createNotification(ID, 'Rejected', po.requesterName);                    // RULE 29
        await createAuditLog(req, ID, 'REJECTED', 'Submitted', 'Rejected', comments); // RULE 31

        return await SELECT.one.from(PurchaseOrders).where({ ID });
    });

    // ----------------------------------------------------------------
    // RULE 24: REWORK – Rejected → Draft
    // ----------------------------------------------------------------
    this.on('rework', async (req) => {
        const ID = getPOId(req);
        const po = await SELECT.one.from(PurchaseOrders).where({ ID });
        if (!po) return req.error(404, 'Purchase Order not found.');

        // RULE 24: Only Rejected can be reworked
        if (po.status !== 'Rejected') {
            return req.error(400, `Only Rejected Purchase Orders can be reworked. Current: ${po.status}`);
        }

        // RULE 24: Change status back to Draft
        await UPDATE(PurchaseOrders, ID).with({ status: 'Draft' });

        await createHistory(ID, 'Rejected', 'Draft', req.user.id, 'Reworked for correction'); // RULE 30
        await createAuditLog(req, ID, 'REWORK', 'Rejected', 'Draft', 'PO sent back for rework'); // RULE 31

        return await SELECT.one.from(PurchaseOrders).where({ ID });
    });

    // ----------------------------------------------------------------
    // RULE 25: CANCEL – Draft/Submitted → Cancelled
    // ----------------------------------------------------------------
    this.on('cancel', async (req) => {
        const ID = getPOId(req);
        const po = await SELECT.one.from(PurchaseOrders).where({ ID });
        if (!po) return req.error(404, 'Purchase Order not found.');

        // RULE 25: Only Draft or Submitted can be cancelled
        if (!['Draft', 'Submitted'].includes(po.status)) {
            return req.error(400, `Only Draft or Submitted Purchase Orders can be cancelled. Current: ${po.status}`);
        }

        // RULE 25: Change status to Cancelled
        await UPDATE(PurchaseOrders, ID).with({ status: 'Cancelled' });

        await createHistory(ID, po.status, 'Cancelled', req.user.id, 'Purchase Order cancelled'); // RULE 30
        await createNotification(ID, 'Cancelled', po.requesterName);                                // RULE 29
        await createAuditLog(req, ID, 'CANCELLED', po.status, 'Cancelled', 'PO cancelled');         // RULE 31

        return await SELECT.one.from(PurchaseOrders).where({ ID });
    });

    // ----------------------------------------------------------------
    // EXTENDED WORKFLOW: ISSUE – Approved → Issued
    // ----------------------------------------------------------------
    this.on('issue', async (req) => {
        const ID = getPOId(req);
        if (!ID) return req.error(400, 'Purchase Order ID is missing.');

        const po = await SELECT.one.from(PurchaseOrders).where({ ID });
        if (!po) return req.error(404, 'Purchase Order not found.');

        // Only Approved can be issued
        if (po.status !== 'Approved') {
            return req.error(400, `Only Approved Purchase Orders can be issued. Current: ${po.status}`);
        }

        await UPDATE(PurchaseOrders, ID).with({ status: 'Issued' });

        await createHistory(ID, 'Approved', 'Issued', req.user.id, 'PO issued');   // RULE 30
        await createNotification(ID, 'Issued', po.requesterName);                   // RULE 29
        await createAuditLog(req, ID, 'ISSUED', 'Approved', 'Issued', 'PO issued'); // RULE 31

        return await SELECT.one.from(PurchaseOrders).where({ ID });
    });

    // ----------------------------------------------------------------
    // EXTENDED WORKFLOW: COMPLETE – Issued → Completed
    // ----------------------------------------------------------------
    this.on('complete', async (req) => {
        const ID = getPOId(req);
        if (!ID) return req.error(400, 'Purchase Order ID is missing.');

        const po = await SELECT.one.from(PurchaseOrders).where({ ID });
        if (!po) return req.error(404, 'Purchase Order not found.');

        // Only Issued can be completed
        if (po.status !== 'Issued') {
            return req.error(400, `Only Issued Purchase Orders can be completed. Current: ${po.status}`);
        }

        await UPDATE(PurchaseOrders, ID).with({ status: 'Completed' });

        await createHistory(ID, 'Issued', 'Completed', req.user.id, 'PO completed');       // RULE 30
        await createNotification(ID, 'Completed', po.requesterName);                        // RULE 29
        await createAuditLog(req, ID, 'COMPLETED', 'Issued', 'Completed', 'PO completed'); // RULE 31

        return await SELECT.one.from(PurchaseOrders).where({ ID });
    });

    // ================================================================
    // VIRTUAL FIELDS – UI support
    // ================================================================
    this.after('READ', PurchaseOrders, (data) => {
        const rows = Array.isArray(data) ? data : [data];
        for (const r of rows) {
            if (!r) continue;
            r.hideSubmit = r.status !== 'Draft';                              // RULE 21
            r.hideApprove = r.status !== 'Submitted';                          // RULE 22
            r.hideReject = r.status !== 'Submitted';                          // RULE 23
            r.canCancel = r.status === 'Draft' || r.status === 'Submitted';  // RULE 25
            r.canRework = r.status === 'Rejected';                           // RULE 24
            r.hideIssue = r.status !== 'Approved';                           // Extended
            r.hideComplete = r.status !== 'Issued';                             // Extended
        }
    });

    // ================================================================
    // CRITICALITY FOR AUDIT LOGS (UI colors)
    // ================================================================
    this.after('READ', PurchaseOrderAuditLogs, (logs) => {
        const setCrit = (log) => {
            if (!log) return;
            switch (log.newStatus) {
                case 'Draft': log.criticality = 2; break;
                case 'Submitted': log.criticality = 3; break;
                case 'Approved': log.criticality = 3; break;
                case 'Issued': log.criticality = 3; break;
                case 'Completed': log.criticality = 3; break;
                case 'Rejected': log.criticality = 1; break;
                case 'Cancelled': log.criticality = 1; break;
                default: log.criticality = 0;
            }
        };
        if (Array.isArray(logs)) logs.forEach(setCrit);
        else setCrit(logs);
    });
});