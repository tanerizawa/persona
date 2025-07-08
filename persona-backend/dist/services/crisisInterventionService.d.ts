export declare class CrisisInterventionService {
    static logCrisisEvent(userId: string, crisisLevel: 'low' | 'medium' | 'high' | 'critical', triggerSource: string, detectedKeywords: string[], userMessage?: string): Promise<void>;
    static recordIntervention(crisisEventId: string, interventionType: string, resourcesProvided: string[], professionalContactMade?: boolean): Promise<void>;
    static getCrisisHistory(userId: string): Promise<any[]>;
    static getCrisisResources(language?: string): Promise<{
        hotlines: any[];
        emergencyContacts: any[];
        mentalHealthResources: any[];
        selfCareGuides: any[];
    }>;
    static triggerEmergencyProtocol(userId: string, crisisLevel: 'high' | 'critical', location?: string): Promise<{
        emergencyContactsSent: boolean;
        resourcesProvided: string[];
        followUpScheduled: boolean;
    }>;
}
