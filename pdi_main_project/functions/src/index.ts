// // Start writing functions
// // https://firebase.google.com/docs/functions/typescript

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const createSchoolAdmin = functions.https.onCall(async (request:
    functions.https.CallableRequest<any>) => {
  const {data, auth: context} = request;

  // sprawdzenie, czy użytkownik jest zalogowany i ma uprawnienia administratora
  if (!context || !context.token?.superAdmin) {
    throw new functions.https.HttpsError("permission-denied",
      "Only superAdmins can create new schoolAdmins");
  }

  const {name, surname, email, password, schoolId} = data;

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
      name: name,
      surname: surname,
      email: email,
      role: "schoolAdmin",
      school_id: admin.firestore().collection("schools").doc(schoolId),
    });

    return {message: `User ${email} created successfully.`};
  } catch (error) {
    throw new functions.https.HttpsError("unknown",
      (error as Error).message, error);
  }
});

export const createUser = functions.https.onCall(async (request:
    functions.https.CallableRequest<any>) => {
  const {data, auth: context} = request;

  // sprawdzenie, czy użytkownik jest zalogowany i ma uprawnienia
  // administratora szkoły
  if (!context || !context.token?.schoolAdmin) {
    throw new functions.https.HttpsError("permission-denied",
      "Only admins can create new users");
  }

  const {name, surname, email, password, role, schoolId, classId,
    parentId} = data;

  try {
    if (role === "superAdmin" || role === "schoolAdmin") {
      throw new functions.https.HttpsError("invalid-argument",
        "Cannot create an admin user.");
    }

    // utworzenie nowego użytkownika w Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
    });

    // ustawienie niestandardowych roszczeń (custom claims) dla użytkownika
    await admin.auth().setCustomUserClaims(userRecord.uid, {[role]: true});

    // zapisanie danych użytkownika w Firestore
    if (role === "student") {
      await admin.firestore().collection("users").doc(userRecord.uid).set({
        name: name,
        surname: surname,
        email: email,
        role: role,
        school_id: admin.firestore().collection("schools").doc(schoolId),
        class_id: admin.firestore().collection("schools").doc(schoolId)
          .collection("classes").doc(classId),
        parent_id: admin.firestore().collection("users").doc(parentId),
      });
    } else {
      await admin.firestore().collection("users").doc(userRecord.uid).set({
        name: name,
        surname: surname,
        email: email,
        role: role,
        school_id: admin.firestore().collection("schools").doc(schoolId),
      });
    }

    return {message: `User ${email} created successfully.`};
  } catch (error) {
    throw new functions.https.HttpsError("unknown",
      (error as Error).message, error);
  }
});
