import { Injectable, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

/** Initialises firebase-admin once from env (or ADC when running inside Firebase Functions). */
@Injectable()
export class FirebaseService {
  private readonly logger = new Logger(FirebaseService.name);
  readonly app: admin.app.App;

  constructor() {
    if (admin.apps.length) {
      this.app = admin.app();
      return;
    }
    const { FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY } = process.env;
    if (FIREBASE_PROJECT_ID && FIREBASE_CLIENT_EMAIL && FIREBASE_PRIVATE_KEY) {
      this.app = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: FIREBASE_PROJECT_ID,
          clientEmail: FIREBASE_CLIENT_EMAIL,
          privateKey: FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        }),
      });
    } else {
      this.logger.warn('Firebase service-account env not set; using application default credentials');
      this.app = admin.initializeApp();
    }
  }

  verifyIdToken(token: string) {
    return this.app.auth().verifyIdToken(token, true);
  }

  getFirestore() {
    return this.app.firestore();
  }

  async sendPushNotification(fcmToken: string, payload: { title: string; body: string; data?: Record<string, string> }) {
    if (!fcmToken) return;
    try {
      await this.app.messaging().send({
        token: fcmToken,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data,
      });
    } catch (err: any) {
      this.logger.warn(`Failed to send FCM push notification: ${err.message}`);
    }
  }
}

