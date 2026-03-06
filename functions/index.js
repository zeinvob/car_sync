const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onBookingCreatedCreateNotificationAndPush = onDocumentCreated(
    "bookings/{bookingId}",
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) return;

      const booking = snapshot.data();
      const bookingId = event.params.bookingId;

      const customerId = booking.customerId || "";
      const workshopId = booking.workshopId || "";
      const serviceType = booking.serviceType || "Service";

      let customerName = "A customer";
      let workshopName = "Workshop";

      if (customerId) {
        const customerDoc = await admin
            .firestore()
            .collection("users")
            .doc(customerId)
            .get();

        if (customerDoc.exists) {
          const customerData = customerDoc.data() || {};
          customerName =
          customerData.fullName ||
          customerData.name ||
          customerData.username ||
          "A customer";
        }
      }

      if (workshopId) {
        const workshopDoc = await admin
            .firestore()
            .collection("workshops")
            .doc(workshopId)
            .get();

        if (workshopDoc.exists) {
          const workshopData = workshopDoc.data() || {};
          workshopName = workshopData.name || "Workshop";
        }
      }

      await admin.firestore().collection("notifications").add({
        targetRole: "admin",
        type: "new_booking",
        title: "New Booking",
        body:
        `${customerName} placed a ${serviceType} booking ` +
        `for ${workshopName}`,
        relatedBookingId: bookingId,
        relatedWorkshopId: workshopId,
        extraData: {
          bookingId,
          workshopId,
          workshopName,
          customerName,
          serviceType,
        },
        isReadBy: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      const adminsSnap = await admin
          .firestore()
          .collection("users")
          .where("role", "==", "admin")
          .get();

      const tokens = [];

      for (const doc of adminsSnap.docs) {
        const data = doc.data() || {};
        if (data.fcmToken) {
          tokens.push(data.fcmToken);
        }
      }

      if (tokens.length === 0) {
        console.log("No admin FCM tokens found");
        return;
      }

      const message = {
        notification: {
          title: "New Booking",
          body:
          `${customerName} placed a ${serviceType} booking ` +
          `for ${workshopName}`,
        },
        data: {
          type: "new_booking",
          bookingId,
          workshopId,
          workshopName,
        },
        tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      console.log(
          `Push sent. Success: ${response.successCount}, ` +
        `Failure: ${response.failureCount}`,
      );
    },
);
