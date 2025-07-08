import { Router } from 'express';
import { CrisisInterventionService } from '../services/crisisInterventionService';
import { authenticateToken } from '../middlewares/auth';
import { ApiError } from '../types';

const router = Router();

// Log crisis event
router.post('/log-crisis', authenticateToken, async (req, res, next) => {
  try {
    const { crisisLevel, triggerSource, detectedKeywords, userMessage } = req.body;

    if (!crisisLevel || !triggerSource || !detectedKeywords) {
      throw new ApiError(400, 'Crisis level, trigger source, and detected keywords are required');
    }

    await CrisisInterventionService.logCrisisEvent(
      req.user!.id,
      crisisLevel,
      triggerSource,
      detectedKeywords,
      userMessage
    );

    res.status(200).json({
      success: true,
      message: 'Crisis event logged successfully'
    });
  } catch (error) {
    next(error);
  }
});

// Record intervention
router.post('/record-intervention', authenticateToken, async (req, res, next) => {
  try {
    const { crisisEventId, interventionType, resourcesProvided, professionalContactMade } = req.body;

    if (!crisisEventId || !interventionType) {
      throw new ApiError(400, 'Crisis event ID and intervention type are required');
    }

    await CrisisInterventionService.recordIntervention(
      crisisEventId,
      interventionType,
      resourcesProvided || [],
      professionalContactMade || false
    );

    res.status(200).json({
      success: true,
      message: 'Intervention recorded successfully'
    });
  } catch (error) {
    next(error);
  }
});

// Get crisis history
router.get('/crisis-history', authenticateToken, async (req, res, next) => {
  try {
    const crisisHistory = await CrisisInterventionService.getCrisisHistory(req.user!.id);

    res.status(200).json({
      success: true,
      data: crisisHistory
    });
  } catch (error) {
    next(error);
  }
});

// Get crisis resources
router.get('/crisis-resources', authenticateToken, async (req, res, next) => {
  try {
    const { language = 'id' } = req.query;
    const resources = await CrisisInterventionService.getCrisisResources(language as string);

    res.status(200).json({
      success: true,
      data: resources
    });
  } catch (error) {
    next(error);
  }
});

export default router;
