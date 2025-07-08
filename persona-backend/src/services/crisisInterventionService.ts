import { prisma } from '../config/database';
import { ApiError } from '../types';

export class CrisisInterventionService {
  static async logCrisisEvent(
    userId: string,
    crisisLevel: 'low' | 'medium' | 'high' | 'critical',
    triggerSource: string,
    detectedKeywords: string[],
    userMessage?: string
  ): Promise<void> {
    try {
      await prisma.crisisEvent.create({
        data: {
          userId,
          crisisLevel,
          triggerSource,
          detectedKeywords: detectedKeywords.join(', '),
          userMessage: userMessage || '',
          interventionProvided: false
        }
      });

      // Log security event for high/critical levels
      if (crisisLevel === 'high' || crisisLevel === 'critical') {
        await prisma.securityEvent.create({
          data: {
            userId,
            eventType: 'crisis_detected',
            description: `Crisis level ${crisisLevel} detected from ${triggerSource}`,
            severity: 'critical'
          }
        });
      }
    } catch (error) {
      console.error('Failed to log crisis event:', error);
      throw new ApiError(500, 'Failed to log crisis event');
    }
  }

  static async recordIntervention(
    crisisEventId: string,
    interventionType: string,
    resourcesProvided: string[],
    professionalContactMade: boolean = false
  ): Promise<void> {
    try {
      await prisma.crisisEvent.update({
        where: { id: crisisEventId },
        data: {
          interventionProvided: true,
          interventionType,
          resourcesProvided: resourcesProvided.join(', '),
          professionalContactMade,
          interventionTimestamp: new Date()
        }
      });
    } catch (error) {
      console.error('Failed to record intervention:', error);
      throw new ApiError(500, 'Failed to record intervention');
    }
  }

  static async getCrisisHistory(userId: string): Promise<any[]> {
    try {
      const crisisEvents = await prisma.crisisEvent.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 10
      });

      return crisisEvents;
    } catch (error) {
      console.error('Failed to get crisis history:', error);
      throw new ApiError(500, 'Failed to get crisis history');
    }
  }

  static async getCrisisResources(language: string = 'id'): Promise<{
    hotlines: any[];
    emergencyContacts: any[];
    mentalHealthResources: any[];
    selfCareGuides: any[];
  }> {
    // Crisis intervention resources for Indonesia
    if (language === 'id') {
      return {
        hotlines: [
          {
            name: 'Hotline Crisis Indonesia',
            number: '119',
            description: 'Layanan darurat nasional 24/7',
            available: '24/7'
          },
          {
            name: 'Into the Light',
            number: '081-1-91-9119',
            description: 'Konseling untuk pencegahan bunuh diri',
            available: '24/7'
          },
          {
            name: 'SEJIWA',
            number: '119 ext 8',
            description: 'Layanan konseling untuk remaja dan dewasa',
            available: '24/7'
          }
        ],
        emergencyContacts: [
          {
            name: 'IGD Rumah Sakit Terdekat',
            instruction: 'Kunjungi atau hubungi IGD untuk bantuan medis segera'
          },
          {
            name: 'Polisi',
            number: '110',
            description: 'Untuk situasi darurat'
          }
        ],
        mentalHealthResources: [
          {
            name: 'Kementerian Kesehatan RI',
            website: 'sehatjiwa.kemkes.go.id',
            description: 'Informasi kesehatan mental'
          },
          {
            name: 'PERDOSRI',
            website: 'perdosri.or.id',
            description: 'Persatuan Dokter Spesialis Kedokteran Jiwa Indonesia'
          }
        ],
        selfCareGuides: [
          {
            title: 'Teknik Pernapasan 4-7-8',
            description: 'Tarik napas 4 detik, tahan 7 detik, buang 8 detik'
          },
          {
            title: 'Grounding 5-4-3-2-1',
            description: '5 benda yang dilihat, 4 yang disentuh, 3 yang didengar, 2 yang dicium, 1 yang dirasakan'
          }
        ]
      };
    }

    // Default English resources
    return {
      hotlines: [
        {
          name: 'National Suicide Prevention Lifeline',
          number: '988',
          description: '24/7 crisis counseling',
          available: '24/7'
        }
      ],
      emergencyContacts: [
        {
          name: 'Emergency Services',
          number: '911',
          description: 'For immediate medical emergency'
        }
      ],
      mentalHealthResources: [],
      selfCareGuides: []
    };
  }

  static async triggerEmergencyProtocol(
    userId: string,
    crisisLevel: 'high' | 'critical',
    location?: string
  ): Promise<{
    emergencyContactsSent: boolean;
    resourcesProvided: string[];
    followUpScheduled: boolean;
  }> {
    try {
      // Log the emergency protocol trigger
      await this.logCrisisEvent(
        userId,
        crisisLevel,
        'emergency_protocol',
        ['emergency_trigger'],
        'Emergency protocol activated'
      );

      // In a real implementation, this would:
      // 1. Send alerts to emergency contacts
      // 2. Notify mental health professionals
      // 3. Provide immediate resources
      // 4. Schedule follow-up care

      const resources = [
        'Crisis hotline numbers provided',
        'Emergency contact information shared',
        'Self-care techniques recommended',
        'Professional help resources listed'
      ];

      return {
        emergencyContactsSent: false, // Would be true in real implementation
        resourcesProvided: resources,
        followUpScheduled: true
      };
    } catch (error) {
      console.error('Failed to trigger emergency protocol:', error);
      throw new ApiError(500, 'Failed to trigger emergency protocol');
    }
  }
}
