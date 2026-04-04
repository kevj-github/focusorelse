const admin = require("firebase-admin");
const {
	onDocumentCreated,
	onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { logger } = require("firebase-functions");

admin.initializeApp();

function normalizeRecurrence(recurrence) {
	if (recurrence == null) {
		return null;
	}

	const normalized = `${recurrence}`.trim().toLowerCase();
	if (!normalized || normalized === "none") {
		return null;
	}

	if (
		normalized === "daily" ||
		normalized === "weekly" ||
		normalized === "monthly"
	) {
		return normalized;
	}

	return null;
}

function calculateNextDeadline(currentDeadline, cadence) {
	if (!(currentDeadline instanceof Date)) {
		return null;
	}

	if (cadence === "daily") {
		return new Date(currentDeadline.getTime() + 24 * 60 * 60 * 1000);
	}

	if (cadence === "weekly") {
		return new Date(currentDeadline.getTime() + 7 * 24 * 60 * 60 * 1000);
	}

	const nextMonth = new Date(
		currentDeadline.getFullYear(),
		currentDeadline.getMonth() + 1,
		1,
		currentDeadline.getHours(),
		currentDeadline.getMinutes(),
		currentDeadline.getSeconds(),
		currentDeadline.getMilliseconds(),
	);
	const lastDayOfNextMonth = new Date(
		nextMonth.getFullYear(),
		nextMonth.getMonth() + 1,
		0,
	);
	const targetDay =
		currentDeadline.getDate() <= lastDayOfNextMonth.getDate()
			? currentDeadline.getDate()
			: lastDayOfNextMonth.getDate();

	return new Date(
		nextMonth.getFullYear(),
		nextMonth.getMonth(),
		targetDay,
		currentDeadline.getHours(),
		currentDeadline.getMinutes(),
		currentDeadline.getSeconds(),
		currentDeadline.getMilliseconds(),
	);
}

function recurringInstanceId(seriesId, deadline) {
	return `${seriesId}_${deadline.getTime()}`.replace(/[^A-Za-z0-9_-]/g, "_");
}

async function createNextRecurringPactIfNeeded(pactId, pactData) {
	const cadence = normalizeRecurrence(pactData.recurrence);
	if (!cadence) {
		return;
	}

	if (pactData.status !== "completed") {
		return;
	}

	const deadline =
		pactData.deadline instanceof admin.firestore.Timestamp
			? pactData.deadline.toDate()
			: null;
	if (!deadline) {
		logger.warn("Recurring pact completion missing deadline", { pactId });
		return;
	}

	const createdAt =
		pactData.createdAt instanceof admin.firestore.Timestamp
			? pactData.createdAt.toDate()
			: null;
	if (!createdAt) {
		logger.warn("Recurring pact completion missing createdAt", { pactId });
		return;
	}

	const seriesId =
		`${pactData.recurrenceSeriesId || ""}`.trim() ||
		`${pactData.userId}_${createdAt.getTime()}`;
	const nextDeadline = calculateNextDeadline(deadline, cadence);
	if (!nextDeadline) {
		return;
	}

	const recurrenceEndsAt =
		pactData.recurrenceEndsAt instanceof admin.firestore.Timestamp
			? pactData.recurrenceEndsAt.toDate()
			: null;
	if (recurrenceEndsAt && nextDeadline > recurrenceEndsAt) {
		return;
	}

	const nextPactId = recurringInstanceId(seriesId, nextDeadline);
	const pactRef = admin.firestore().collection("pacts").doc(nextPactId);

	await admin.firestore().runTransaction(async (transaction) => {
		const existing = await transaction.get(pactRef);
		if (existing.exists) {
			return;
		}

		transaction.set(pactRef, {
			userId: pactData.userId,
			taskDescription: pactData.taskDescription || "",
			deadline: admin.firestore.Timestamp.fromDate(nextDeadline),
			recurrence: cadence,
			recurrenceEndsAt: recurrenceEndsAt
				? admin.firestore.Timestamp.fromDate(recurrenceEndsAt)
				: null,
			recurrenceSeriesId: seriesId,
			verificationType: pactData.verificationType || "selfAttest",
			verifierId: pactData.verifierId || null,
			consequenceType: pactData.consequenceType || "socialSharing",
			consequenceDetails: pactData.consequenceDetails || {},
			status: "active",
			evidenceUrl: null,
			evidenceSubmittedAt: null,
			verificationResult: null,
			createdAt: admin.firestore.Timestamp.now(),
			completedAt: null,
			reminders: [],
			consequenceStatus: "none",
			consequenceEvidenceUrl: null,
			consequenceVerificationResult: null,
			consequenceSubmittedAt: null,
			consequenceReviewedAt: null,
		});
	});

	logger.info("Created next recurring pact", {
		pactId,
		nextPactId,
		seriesId,
		cadence,
	});
}

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

exports.createRecurringPactOnCompletion = onDocumentUpdated(
	"pacts/{pactId}",
	async (event) => {
		const before = event.data && event.data.before;
		const after = event.data && event.data.after;
		if (!before || !after) {
			return;
		}

		const beforeData = before.data() || {};
		const afterData = after.data() || {};
		if (
			beforeData.status === afterData.status ||
			afterData.status !== "completed"
		) {
			return;
		}

		try {
			await createNextRecurringPactIfNeeded(after.id, afterData);
		} catch (error) {
			logger.error("Failed to create recurring pact on completion", {
				pactId: after.id,
				error,
			});
		}
	},
);
