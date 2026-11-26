import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { handlePartnerStart } from './partner_start/handler';

initializeApp();

// Firestore 在 nam5,触发器放同一多区域内的 us-central1。
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

/** 伙伴开始运动推送(change add-partner-start-push)。处理完总是删除信号文档。 */
export const partnerStartPush = onDocumentCreated(
  'users/{userId}/workout_starts/{sessionId}',
  async (event) => {
    const { userId, sessionId } = event.params;
    try {
      const data = event.data?.data();
      if (data) {
        await handlePartnerStart({ senderId: userId, sessionId, data });
      }
    } finally {
      await getFirestore()
        .doc(`users/${userId}/workout_starts/${sessionId}`)
        .delete()
        .catch((e) => logger.warn('partner_start: cleanup failed', e));
    }
  },
);
