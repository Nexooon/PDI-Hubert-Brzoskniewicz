// // Start writing functions
// // https://firebase.google.com/docs/functions/typescript

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const makeMeAdmin = functions.https.onCall(async () => {
  try {
    await admin.auth().setCustomUserClaims("id...",
      {admin: true});

    return {message: "Admin claims added successfully."};
  } catch (error) {
    throw new functions.https.HttpsError("unknown",
      (error as Error).message, error);
  }
});

export const createSchoolAdmin = functions.https.onCall(async (request:
    functions.https.CallableRequest<any>) => {
  const {data, auth: context} = request;

  // sprawdzenie, czy użytkownik jest zalogowany i ma uprawnienia administratora
  if (!context || !context.token?.admin) {
    throw new functions.https.HttpsError("permission-denied",
      "Only admins can create new school admins");
  }

  const {email, password} = data;

  try {
    // utworzenie nowego użytkownika w Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
    });

    // ustawienie niestandardowych roszczeń (custom claims) dla użytkownika
    await admin.auth().setCustomUserClaims(userRecord.uid, {schoolAdmin: true});

    // zapisanie danych użytkownika w Firestore
    await admin.firestore().collection("users").doc(userRecord.uid).set({
      email: email,
      role: "schoolAdmin",
    //   school_id: "id_szkoły",
    });

    // Dodaj szkołę do kolekcji szkół

    return {message: `User ${email} created successfully.`};
  } catch (error) {
    throw new functions.https.HttpsError("unknown",
      (error as Error).message, error);
  }
});

export const createUser = functions.https.onCall(async (request:
    functions.https.CallableRequest<any>) => {
  const {data, auth: context} = request;

  // sprawdzenie, czy użytkownik jest zalogowany i ma uprawnienia administratora szkoły
  if (!context || !context.token?.schoolAdmin) {
    throw new functions.https.HttpsError("permission-denied",
      "Only admins can create new users");
  }

  const {email, password, role} = data;

  try {
    if (role === "admin" || role === "schoolAdmin") {
      throw new functions.https.HttpsError("invalid-argument",
        "Cannot create an admin user.");
    }

    // utworzenie nowego użytkownika w Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
    });

    // ustawienie niestandardowych roszczeń (custom claims) dla użytkownika
    await admin.auth().setCustomUserClaims(userRecord.uid, {role});

    // zapisanie danych użytkownika w Firestore
    await admin.firestore().collection("users").doc(userRecord.uid).set({
      email: email,
      role: role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {message: `User ${email} created successfully.`};
  } catch (error) {
    throw new functions.https.HttpsError("unknown",
      (error as Error).message, error);
  }
});
