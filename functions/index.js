const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");

admin.initializeApp();

exports.sendPushForNotification = onDocumentCreated(
	"notifications/{notificationId}",
	async (event) => {
		const snapshot = event.data;
		if (!snapshot) {
			return;
		}

		const notification = snapshot.data() || {};
		const recipientUserId = `${notification.recipientUserId || ""}`.trim();
		if (!recipientUserId) {
			logger.warn("Notification missing recipientUserId", {
				notificationId: snapshot.id,
			});
			return;
		}

		const userDoc = await admin
			.firestore()
			.collection("users")
			.doc(recipientUserId)
			.get();
		if (!userDoc.exists) {
			logger.warn("Recipient user not found", { recipientUserId });
			return;
		}

		const userData = userDoc.data() || {};
		const token = `${userData.fcmToken || ""}`.trim();
		if (!token) {
			logger.info("Recipient has no FCM token", { recipientUserId });
			return;
		}

		const title = `${notification.title || "Focus or Else"}`;
		const body = `${notification.body || ""}`;
		const payload = {
			notificationId: snapshot.id,
			pactId: `${notification.pactId || ""}`,
			type: `${notification.type || ""}`,
			actorUserId: `${notification.actorUserId || ""}`,
		};

		try {
			await admin.messaging().send({
				token,
				notification: {
					title,
					body,
				},
				data: payload,
				android: {
					priority: "high",
					notification: {
						channelId: "default_channel",
						priority: "high",
					},
				},
				apns: {
					headers: {
						"apns-priority": "10",
					},
					payload: {
						aps: {
							sound: "default",
						},
					},
				},
			});
		} catch (error) {
			logger.error("Failed to send push notification", {
				notificationId: snapshot.id,
				recipientUserId,
				error,
			});

			if (
				error &&
				error.code === "messaging/registration-token-not-registered"
			) {
				await admin
					.firestore()
					.collection("users")
					.doc(recipientUserId)
					.set(
						{
							fcmToken: admin.firestore.FieldValue.delete(),
						},
						{ merge: true },
					);
			}
		}
	},
);
