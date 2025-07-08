"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const crisisInterventionService_1 = require("../services/crisisInterventionService");
const auth_1 = require("../middlewares/auth");
const types_1 = require("../types");
const router = (0, express_1.Router)();
// Log crisis event
router.post('/log-crisis', auth_1.authenticateToken, async (req, res, next) => {
    try {
        const { crisisLevel, triggerSource, detectedKeywords, userMessage } = req.body;
        if (!crisisLevel || !triggerSource || !detectedKeywords) {
            throw new types_1.ApiError(400, 'Crisis level, trigger source, and detected keywords are required');
        }
        await crisisInterventionService_1.CrisisInterventionService.logCrisisEvent(req.user.id, crisisLevel, triggerSource, detectedKeywords, userMessage);
        res.status(200).json({
            success: true,
            message: 'Crisis event logged successfully'
        });
    }
    catch (error) {
        next(error);
    }
});
// Record intervention
router.post('/record-intervention', auth_1.authenticateToken, async (req, res, next) => {
    try {
        const { crisisEventId, interventionType, resourcesProvided, professionalContactMade } = req.body;
        if (!crisisEventId || !interventionType) {
            throw new types_1.ApiError(400, 'Crisis event ID and intervention type are required');
        }
        await crisisInterventionService_1.CrisisInterventionService.recordIntervention(crisisEventId, interventionType, resourcesProvided || [], professionalContactMade || false);
        res.status(200).json({
            success: true,
            message: 'Intervention recorded successfully'
        });
    }
    catch (error) {
        next(error);
    }
});
// Get crisis history
router.get('/crisis-history', auth_1.authenticateToken, async (req, res, next) => {
    try {
        const crisisHistory = await crisisInterventionService_1.CrisisInterventionService.getCrisisHistory(req.user.id);
        res.status(200).json({
            success: true,
            data: crisisHistory
        });
    }
    catch (error) {
        next(error);
    }
});
// Get crisis resources
router.get('/crisis-resources', auth_1.authenticateToken, async (req, res, next) => {
    try {
        const { language = 'id' } = req.query;
        const resources = await crisisInterventionService_1.CrisisInterventionService.getCrisisResources(language);
        res.status(200).json({
            success: true,
            data: resources
        });
    }
    catch (error) {
        next(error);
    }
});
exports.default = router;
//# sourceMappingURL=crisisRoutes.js.map