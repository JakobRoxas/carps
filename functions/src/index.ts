import { initializeApp } from "firebase-admin/app";
import {
  Firestore,
  Transaction,
  getFirestore,
} from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { isDeepStrictEqual } from "node:util";

initializeApp();
const db = getFirestore();
const REGION = "asia-southeast1";

type Data = Record<string, unknown>;
type CallableAuth = { uid: string };

const COLLECTIONS = [
  "users",
  "events",
  "invitations",
  "registrations",
  "passes",
  "attendance",
  "posts",
  "reviews",
  "notifications",
  "cases",
] as const;
type Collection = (typeof COLLECTIONS)[number];

const USER_FIELDS = [
  "id", "displayName", "username", "email", "avatarAsset", "bio", "area",
  "interests", "followingIds", "hostingEnabled", "builderName", "builderAbout",
  "isAdmin", "termsAccepted", "primaryRole", "profileComplete", "discoveryDone",
  "contactDiscoveryOptIn",
];
const EVENT_FIELDS = [
  "id", "hostId", "coHostIds", "title", "description", "topic", "venue", "area",
  "start", "end", "visibility", "coverAsset", "capacity", "featuredOnProfile",
  "status", "notices", "seriesLabel",
];
const INVITATION_FIELDS = [
  "id", "eventId", "inviteeId", "invitedById", "kind", "status", "createdAt",
];
const REGISTRATION_FIELDS = [
  "id", "eventId", "userId", "status", "requestedAt", "note", "decidedAt", "passId",
];
const PASS_FIELDS = [
  "id", "token", "eventId", "userId", "registrationId", "issuedAt", "revoked",
];
const ATTENDANCE_FIELDS = [
  "eventId", "userId", "arrivedAt", "scannedById", "passId",
];
const POST_FIELDS = [
  "id", "eventId", "authorId", "body", "photoAsset", "taggedIds", "likedByIds",
  "comments", "createdAt",
];
const REVIEW_FIELDS = ["id", "eventId", "authorId", "rating", "text", "createdAt"];
const NOTIFICATION_FIELDS = [
  "id", "userId", "kind", "title", "body", "createdAt", "eventId", "postId",
  "caseId", "read", "emailSimulated",
];
const CASE_FIELDS = [
  "id", "reporterId", "category", "details", "link", "createdAt", "assignedAdminId",
  "status", "outcome", "decisionNote", "closedAt", "hostConfirmed",
];
const ALLOWED_FIELDS: Record<Collection, string[]> = {
  users: USER_FIELDS,
  events: EVENT_FIELDS,
  invitations: INVITATION_FIELDS,
  registrations: REGISTRATION_FIELDS,
  passes: PASS_FIELDS,
  attendance: ATTENDANCE_FIELDS,
  posts: POST_FIELDS,
  reviews: REVIEW_FIELDS,
  notifications: NOTIFICATION_FIELDS,
  cases: CASE_FIELDS,
};

function fail(code: HttpsError["code"], message: string): never {
  throw new HttpsError(code, message);
}

function requireAuth(auth: CallableAuth | undefined): string {
  if (!auth) fail("unauthenticated", "Sign in to continue.");
  return auth.uid;
}

function object(value: unknown, label: string): Data {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    fail("invalid-argument", `${label} must be an object.`);
  }
  return value as Data;
}

function requiredString(data: Data, key: string): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim() === "") {
    fail("invalid-argument", `${key} must be a non-empty string.`);
  }
  return value;
}

function stringList(data: Data, key: string): string[] {
  const value = data[key];
  if (!Array.isArray(value) || !value.every((item) => typeof item === "string")) {
    fail("invalid-argument", `${key} must be a list of strings.`);
  }
  return value as string[];
}

function dateMillis(value: unknown, label: string): number {
  if (typeof value !== "string" || !Number.isFinite(Date.parse(value))) {
    fail("invalid-argument", `${label} must be an ISO date/time.`);
  }
  return Date.parse(value);
}

function checkFields(data: Data, allowed: string[]): void {
  const unknown = Object.keys(data).find((key) => !allowed.includes(key));
  if (unknown) fail("invalid-argument", `Unsupported field: ${unknown}.`);
}

function strip(data: Data, ...fields: string[]): Data {
  const result = { ...data };
  for (const field of fields) delete result[field];
  return result;
}

function sameExcept(oldData: Data, newData: Data, ...ignored: string[]): boolean {
  return isDeepStrictEqual(strip(oldData, ...ignored), strip(newData, ...ignored));
}

function ref(collection: Collection, id: string) {
  return db.collection(collection).doc(id);
}

async function getData(
  tx: Transaction,
  collection: Collection,
  id: string,
): Promise<Data | undefined> {
  const snapshot = await tx.get(ref(collection, id));
  return snapshot.exists ? (snapshot.data() as Data) : undefined;
}

function exists(data: Data | undefined, message: string): asserts data is Data {
  if (!data) fail("not-found", message);
}

function hostingTeam(event: Data, uid: string): boolean {
  return event.hostId === uid ||
    (Array.isArray(event.coHostIds) && event.coHostIds.includes(uid));
}

function privateEvent(event: Data): boolean {
  return event.visibility === "private";
}

function isEnded(event: Data): boolean {
  return dateMillis(event.end, "event.end") <= Date.now();
}

function validateEvent(data: Data, creating: boolean): void {
  if (data.visibility !== "public" && data.visibility !== "private") {
    fail("invalid-argument", "Event visibility is invalid.");
  }
  if (data.status !== "published" && data.status !== "cancelled") {
    fail("invalid-argument", "Event status is invalid.");
  }
  const start = dateMillis(data.start, "event.start");
  const end = dateMillis(data.end, "event.end");
  if (end <= start) fail("failed-precondition", "End time must follow start time.");
  if (creating && start <= Date.now()) {
    fail("failed-precondition", "New events must start in the future.");
  }
  if (typeof data.title !== "string" || data.title.trim().length < 4) {
    fail("invalid-argument", "Event title must contain at least 4 characters.");
  }
  if (typeof data.venue !== "string" || data.venue.trim() === "") {
    fail("invalid-argument", "Event venue is required.");
  }
  if (!Array.isArray(data.coHostIds) ||
      !data.coHostIds.every((id) => typeof id === "string") ||
      new Set(data.coHostIds).size !== data.coHostIds.length) {
    fail("invalid-argument", "Event co-host list is invalid.");
  }
}

async function requireEvent(
  tx: Transaction,
  eventId: string,
): Promise<Data> {
  const event = await getData(tx, "events", eventId);
  exists(event, "Event not found.");
  return event;
}

async function requireUser(
  tx: Transaction,
  uid: string,
): Promise<Data> {
  const user = await getData(tx, "users", uid);
  exists(user, "Account not found.");
  return user;
}

async function requireRegistration(
  tx: Transaction,
  id: string,
): Promise<Data> {
  const data = await getData(tx, "registrations", id);
  exists(data, "Registration not found.");
  return data;
}

function attendanceIdFor(eventId: string, userId: string): string {
  return `${eventId}_${userId}`;
}

async function matchingDocs(
  firestore: Firestore,
  collection: Collection,
  predicate: (data: Data) => boolean,
): Promise<Data[]> {
  const snapshot = await firestore.collection(collection).get();
  return snapshot.docs
    .map((doc) => doc.data() as Data)
    .filter(predicate);
}

export const getCarpsData = onCall({ region: REGION }, async (request) => {
  const uid = request.auth?.uid;
  const allEvents = (await db.collection("events").get()).docs.map((d) => d.data() as Data);
  const allUsers = (await db.collection("users").get()).docs.map((d) => d.data() as Data);

  if (!uid) {
    return {
      users: allUsers.map((user) => publicUser(user, null)),
      events: allEvents.filter((event) => !privateEvent(event)),
      ...emptyCollections(),
    };
  }

  const [allInvitations, allRegistrations] = await Promise.all([
    matchingDocs(db, "invitations", () => true),
    matchingDocs(db, "registrations", () => true),
  ]);
  const allAttendance = await matchingDocs(db, "attendance", () => true);
  const byId = new Map(allEvents.map((event) => [String(event.id), event]));
  const myInvitations = allInvitations.filter((item) => item.inviteeId === uid);
  const myRegistrations = allRegistrations.filter((item) => item.userId === uid);
  const relevantEvents = new Set<string>();

  for (const event of allEvents) {
    if (!privateEvent(event) || hostingTeam(event, uid)) {
      relevantEvents.add(String(event.id));
    }
  }
  for (const item of [...myInvitations, ...myRegistrations]) {
    relevantEvents.add(String(item.eventId));
  }

  const eventList = allEvents.filter((event) =>
    !privateEvent(event) || relevantEvents.has(String(event.id)));
  const hostingEventIds = new Set(eventList
    .filter((event) => hostingTeam(event, uid))
    .map((event) => String(event.id)));
  const visibleEventIds = new Set(eventList.map((event) => String(event.id)));
  const verifiedPrivateAttendance = new Set(allAttendance
    .filter((item) => {
      const event = byId.get(String(item.eventId));
      return item.userId === uid && event !== undefined && privateEvent(event);
    })
    .map((item) => String(item.eventId)));
  const attendanceRows = allAttendance.filter((item) => {
    const event = byId.get(String(item.eventId));
    if (!event || !visibleEventIds.has(String(item.eventId))) return false;
    return !privateEvent(event) ||
      hostingTeam(event, uid) ||
      verifiedPrivateAttendance.has(String(item.eventId));
  });
  const socialEvents = new Set(eventList
    .filter((event) => !privateEvent(event) ||
      hostingTeam(event, uid) ||
      verifiedPrivateAttendance.has(String(event.id)))
    .map((event) => String(event.id)));

  const [
    invitations, registrations, passes, attendance, posts, reviews,
    notifications, cases,
  ] = await Promise.all([
    matchingDocs(db, "invitations", (item) => item.inviteeId === uid ||
      hostingEventIds.has(String(item.eventId))),
    Promise.resolve(allRegistrations
      .filter((item) => {
        const event = byId.get(String(item.eventId));
        return item.userId === uid ||
          hostingEventIds.has(String(item.eventId)) ||
          (event !== undefined && !privateEvent(event));
      })
      .map((item) => {
        const event = byId.get(String(item.eventId));
        return event && hostingTeam(event, uid)
          ? item
          : { ...item, note: "" };
      })),
    matchingDocs(db, "passes", (item) => item.userId === uid ||
      hostingEventIds.has(String(item.eventId))),
    Promise.resolve(attendanceRows),
    matchingDocs(db, "posts", (item) => socialEvents.has(String(item.eventId))),
    matchingDocs(db, "reviews", (item) => socialEvents.has(String(item.eventId))),
    matchingDocs(db, "notifications", (item) => item.userId === uid),
    matchingDocs(db, "cases", (item) => item.reporterId === uid ||
      (allUsers.some((user) => user.id === uid && user.isAdmin === true) &&
        item.assignedAdminId === uid)),
  ]);

  const users = allUsers.map((user) => publicUser(user, uid));
  return {
    users,
    events: eventList.filter((event) => visibleEventIds.has(String(event.id))),
    invitations,
    registrations,
    passes,
    attendance,
    posts,
    reviews,
    notifications,
    cases,
  };
});

function emptyCollections(): Record<string, Data[]> {
  return {
    invitations: [],
    registrations: [],
    passes: [],
    attendance: [],
    posts: [],
    reviews: [],
    notifications: [],
    cases: [],
  };
}

function publicUser(user: Data, uid: string | null): Data {
  const result = { ...user };
  if (user.id !== uid) {
    result.email = "";
    result.followingIds = [];
    result.termsAccepted = false;
    result.profileComplete = false;
    result.discoveryDone = false;
    result.contactDiscoveryOptIn = false;
    if (uid === null) result.isAdmin = false;
  }
  delete result.password;
  return result;
}

export const saveCarpsDocument = onCall({ region: REGION }, async (request) => {
  const uid = requireAuth(request.auth);
  const input = object(request.data, "request");
  const collection = input.collection;
  if (typeof collection !== "string" ||
      !(COLLECTIONS as readonly string[]).includes(collection)) {
    fail("invalid-argument", "Unsupported collection.");
  }
  const target = collection as Collection;
  const id = requiredString(input, "id");
  const data = object(input.data, "data");
  checkFields(data, ALLOWED_FIELDS[target]);
  const authEmail = request.auth?.token.email;
  await db.runTransaction(async (tx) => {
    const old = await getData(tx, target, id);
    await validateAndWrite(tx, uid, target, id, data, old, authEmail);
  });
  return { ok: true };
});

async function validateAndWrite(
  tx: Transaction,
  uid: string,
  collection: Collection,
  id: string,
  data: Data,
  old: Data | undefined,
  authEmail?: string,
): Promise<void> {
  switch (collection) {
    case "users":
      await saveUser(tx, uid, id, data, old, authEmail);
      return;
    case "events":
      await saveEvent(tx, uid, id, data, old);
      return;
    case "invitations":
      await saveInvitation(tx, uid, id, data, old);
      return;
    case "registrations":
      await saveRegistration(tx, uid, id, data, old);
      return;
    case "passes":
      await savePass(tx, uid, id, data, old);
      return;
    case "attendance":
      await saveAttendance(tx, uid, id, data, old);
      return;
    case "posts":
      await savePost(tx, uid, id, data, old);
      return;
    case "reviews":
      await saveReview(tx, uid, id, data, old);
      return;
    case "notifications":
      await saveNotification(tx, uid, id, data, old);
      return;
    case "cases":
      await saveCase(tx, uid, id, data, old);
      return;
  }
}

async function saveUser(
  tx: Transaction, uid: string, id: string, data: Data, old: Data | undefined,
  authEmail?: string,
): Promise<void> {
  if (id !== uid || data.id !== uid) fail("permission-denied", "You can only edit your own profile.");
  if (typeof authEmail !== "string" || authEmail.trim() === "" ||
      typeof data.email !== "string" ||
      data.email.trim().toLowerCase() !== authEmail.trim().toLowerCase()) {
    fail("permission-denied", "Profile email must match your signed-in email.");
  }
  if (typeof data.isAdmin !== "boolean") {
    fail("invalid-argument", "isAdmin must be present.");
  }
  if (old) {
    if (old.isAdmin !== data.isAdmin) fail("permission-denied", "Admin status is immutable.");
    if (old.id !== uid) fail("permission-denied", "Profile identity cannot change.");
  } else if (data.isAdmin !== false) {
    fail("permission-denied", "Admin status can only be assigned by an administrator.");
  }
  const username = requiredString(data, "username");
  if (!/^[a-z0-9_]{3,20}$/.test(username)) {
    fail("invalid-argument", "Username must be 3–20 lowercase letters, numbers, or underscores.");
  }
  if (data.hostingEnabled !== true && data.hostingEnabled !== false) {
    fail("invalid-argument", "hostingEnabled must be boolean.");
  }
  if (data.hostingEnabled && typeof data.builderName !== "string") {
    fail("invalid-argument", "Builder name is required when hosting is enabled.");
  }
  if (data.hostingEnabled && (data.builderName as string).trim().length < 3) {
    fail("invalid-argument", "Builder name must contain at least 3 characters.");
  }
  if (typeof data.interests !== "undefined" &&
      (!Array.isArray(data.interests) || !data.interests.every((item) => typeof item === "string"))) {
    fail("invalid-argument", "interests must be a list of strings.");
  }
  if (typeof data.followingIds !== "undefined") {
    const following = stringList(data, "followingIds");
    if (following.includes(uid)) fail("failed-precondition", "You cannot follow yourself.");
  }
  const conflict = await tx.get(db.collection("users").where("username", "==", username));
  if (conflict.docs.some((doc) => doc.id !== uid)) {
    fail("already-exists", "That username is already taken.");
  }
  tx.set(ref("users", id), data);
}

async function saveEvent(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (data.id !== id) fail("invalid-argument", "Event id must match its document id.");
  validateEvent(data, !old);
  if (!old) {
    const host = await requireUser(tx, uid);
    if (data.hostId !== uid || host.hostingEnabled !== true ||
        !Array.isArray(data.coHostIds) || data.coHostIds.length !== 0 ||
        data.status !== "published") {
      fail("permission-denied", "Only an enabled builder can create an event.");
    }
  } else {
    if (old.hostId !== data.hostId) fail("permission-denied", "Event host cannot change.");
    if (!hostingTeam(old, uid)) fail("permission-denied", "Only the hosting team can edit this event.");
    if (old.status === "cancelled" && data.status !== "cancelled") {
      fail("failed-precondition", "Cancelled events cannot be restored.");
    }
    if (data.featuredOnProfile !== old.featuredOnProfile && old.hostId !== uid) {
      fail("permission-denied", "Only the builder can feature an event.");
    }
    if (!isDeepStrictEqual(old.coHostIds, data.coHostIds)) {
      fail("permission-denied", "Co-host membership is managed by invitations.");
    }
    if (old.status !== data.status && data.status === "cancelled" && isEnded(old)) {
      fail("failed-precondition", "An ended event cannot be cancelled.");
    }
  }
  if (typeof data.capacity !== "undefined" && data.capacity !== null &&
      (!Number.isInteger(data.capacity) || (data.capacity as number) < 1)) {
    fail("invalid-argument", "Capacity must be a positive integer or null.");
  }
  tx.set(ref("events", id), data);
}

async function saveInvitation(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (data.id !== id) fail("invalid-argument", "Invitation id mismatch.");
  const eventId = requiredString(data, "eventId");
  const event = await requireEvent(tx, eventId);
  if (!old) {
    if (data.status !== "sent" || data.invitedById !== uid ||
        (data.kind !== "guest" && data.kind !== "coHost")) {
      fail("permission-denied", "Invalid invitation creation.");
    }
    const inviteeId = requiredString(data, "inviteeId");
    if (data.kind === "coHost") {
      const host = await requireUser(tx, uid);
      const invitee = await requireUser(tx, inviteeId);
      if (event.hostId !== uid || invitee.hostingEnabled !== true ||
          (event.coHostIds as string[]).includes(inviteeId)) {
        fail("permission-denied", "Only the builder can invite an enabled builder as co-host.");
      }
      if (host.id !== uid) fail("permission-denied", "Invalid inviter.");
    } else {
      await requireUser(tx, inviteeId);
      if (!hostingTeam(event, uid) || hostingTeam(event, inviteeId)) {
        fail("permission-denied", "Only the hosting team can invite a guest.");
      }
    }
    const invitations = await tx.get(db.collection("invitations")
      .where("eventId", "==", eventId));
    if (invitations.docs.some((doc) =>
      doc.get("inviteeId") === inviteeId && doc.get("kind") === data.kind)) {
      fail("already-exists", "This user has already been invited.");
    }
  } else {
    if (!sameExcept(old, data, "status") ||
        old.eventId !== eventId ||
        (old.status !== "sent") ||
        (data.status !== "accepted" && data.status !== "declined") ||
        old.inviteeId !== uid) {
      fail("permission-denied", "Only the invited user may respond to a pending invitation.");
    }
    if (old.kind === "coHost" && data.status === "accepted") {
      const coHosts = Array.isArray(event.coHostIds) ? [...event.coHostIds as string[]] : [];
      if (!coHosts.includes(uid)) {
        coHosts.push(uid);
        tx.set(ref("events", eventId), { ...event, coHostIds: coHosts });
      }
    }
  }
  tx.set(ref("invitations", id), data);
}

async function saveRegistration(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (data.id !== id) fail("invalid-argument", "Registration id mismatch.");
  const eventId = requiredString(data, "eventId");
  const userId = requiredString(data, "userId");
  const event = await requireEvent(tx, eventId);
  const existing = old;
  if (!existing) {
    if (uid !== userId || data.status !== "pending" ||
        event.status !== "published" || dateMillis(event.start, "event.start") <= Date.now() ||
        hostingTeam(event, uid)) {
      fail("permission-denied", "This user cannot request to join this event.");
    }
    const registrations = await tx.get(db.collection("registrations")
      .where("eventId", "==", eventId));
    if (registrations.docs.some((doc) => doc.get("userId") === uid)) {
      fail("already-exists", "A registration already exists for this event.");
    }
    if (privateEvent(event)) {
      const invitation = await tx.get(db.collection("invitations")
        .where("eventId", "==", eventId));
      if (!invitation.docs.some((doc) =>
        doc.get("inviteeId") === uid && doc.get("kind") === "guest")) {
        fail("permission-denied", "Private events are invitation only.");
      }
    }
    if (typeof data.note !== "string") fail("invalid-argument", "Registration note must be text.");
  } else if (existing.status === "withdrawn" && data.status === "pending") {
    if (existing.userId !== uid || existing.eventId !== eventId ||
        id !== existing.id || event.status !== "published" ||
        dateMillis(event.start, "event.start") <= Date.now() ||
        data.passId != null || data.decidedAt != null ||
        typeof data.note !== "string" || typeof data.requestedAt !== "string") {
      fail("permission-denied", "This withdrawn registration cannot be reopened.");
    }
    if (privateEvent(event)) {
      const invitations = await tx.get(db.collection("invitations")
        .where("eventId", "==", eventId));
      if (!invitations.docs.some((doc) =>
        doc.get("inviteeId") === uid && doc.get("kind") === "guest")) {
        fail("permission-denied", "Private events are invitation only.");
      }
    }
  } else if (data.status === "withdrawn") {
    if (existing.userId !== uid || !sameExcept(existing, data, "status", "decidedAt") ||
        !["pending", "approved"].includes(String(existing.status)) ||
        dateMillis(event.start, "event.start") <= Date.now()) {
      fail("permission-denied", "You cannot withdraw this registration.");
    }
    if (existing.passId) {
      const pass = await getData(tx, "passes", String(existing.passId));
      if (pass && pass.revoked !== true) {
        tx.set(ref("passes", String(existing.passId)), { ...pass, revoked: true });
      }
    }
  } else {
    if (existing.status !== "pending" ||
        !["approved", "declined"].includes(String(data.status)) ||
        !hostingTeam(event, uid) || event.status === "cancelled" ||
        !sameExcept(existing, data, "status", "decidedAt", "passId")) {
      fail("permission-denied", "Only the hosting team can decide a pending request.");
    }
    if (data.status === "approved") {
      const passId = requiredString(data, "passId");
      const pass = await getData(tx, "passes", passId);
      if (!pass || pass.registrationId !== id || pass.eventId !== eventId ||
          pass.userId !== userId || pass.revoked === true) {
        fail("failed-precondition", "Approval requires a valid pass for this guest.");
      }
    } else if (data.passId !== existing.passId && data.passId != null) {
      fail("permission-denied", "Declining a request cannot issue a pass.");
    }
  }
  tx.set(ref("registrations", id), data);
}

async function savePass(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (data.id !== id) fail("invalid-argument", "Pass id mismatch.");
  if (!old) {
    const event = await requireEvent(tx, requiredString(data, "eventId"));
    const registration = await requireRegistration(tx, requiredString(data, "registrationId"));
    if (!hostingTeam(event, uid) || registration.status !== "pending" ||
        registration.userId !== data.userId || registration.eventId !== data.eventId ||
        data.revoked !== false || typeof data.token !== "string" || data.token.length < 16) {
      fail("permission-denied", "Only the hosting team can issue a pass for a pending guest.");
    }
    const collision = await tx.get(db.collection("passes").where("token", "==", data.token));
    if (!collision.empty) fail("already-exists", "Pass token already exists.");
  } else if (!sameExcept(old, data, "revoked") ||
      data.revoked !== true || old.revoked === true) {
    fail("permission-denied", "Passes are immutable and may only be revoked.");
  } else {
    const event = await requireEvent(tx, requiredString(old, "eventId"));
    const registration = await requireRegistration(tx, requiredString(old, "registrationId"));
    if (uid !== old.userId && !hostingTeam(event, uid)) {
      fail("permission-denied", "Only the guest or hosting team can revoke this pass.");
    }
    if (uid === old.userId &&
        (registration.userId !== uid || registration.status !== "approved")) {
      fail("permission-denied", "Only your active pass can be revoked.");
    }
  }
  tx.set(ref("passes", id), data);
}

async function saveAttendance(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  const eventId = requiredString(data, "eventId");
  const userId = requiredString(data, "userId");
  if (id !== attendanceIdFor(eventId, userId) || old) {
    fail("already-exists", "Attendance is a unique, immutable first check-in.");
  }
  const event = await requireEvent(tx, eventId);
  const registrations = await tx.get(db.collection("registrations")
    .where("eventId", "==", eventId));
  const registration = registrations.docs
    .map((doc) => doc.data() as Data)
    .find((item) => item.userId === userId && item.status === "approved");
  const passId = requiredString(data, "passId");
  const pass = await getData(tx, "passes", passId);
  const now = Date.now();
  if (!hostingTeam(event, uid) || event.status !== "published" ||
      now < dateMillis(event.start, "event.start") - 6 * 60 * 60 * 1000 ||
      now >= dateMillis(event.end, "event.end") ||
      !registration ||
      registration.passId !== passId || !pass || pass.revoked === true ||
      pass.userId !== userId || pass.eventId !== eventId ||
      pass.registrationId !== registration.id || data.scannedById !== uid) {
    fail("permission-denied", "A valid pass can only be checked in by the hosting team during the scan window.");
  }
  tx.create(ref("attendance", id), {
    ...data,
    arrivedAt: new Date(now).toISOString(),
    scannedById: uid,
  });
}

async function canViewPrivateSocial(
  tx: Transaction, event: Data, uid: string,
): Promise<boolean> {
  if (!privateEvent(event) || hostingTeam(event, uid)) return true;
  const attendance = await getData(tx, "attendance", attendanceIdFor(String(event.id), uid));
  return !!attendance;
}

async function savePost(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (data.id !== id) fail("invalid-argument", "Post id mismatch.");
  const event = await requireEvent(tx, requiredString(data, "eventId"));
  if (!old) {
    if (data.authorId !== uid || event.status === "cancelled" || !isEnded(event) ||
        typeof data.body !== "string" || data.body.trim() === "" ||
        data.body.trim().length > 280 ||
        !Array.isArray(data.taggedIds) ||
        !data.taggedIds.every((item) => typeof item === "string")) {
      fail("failed-precondition", "Only checked-in attendees may post after an event ends.");
    }
    const attendance = await getData(tx, "attendance", attendanceIdFor(String(event.id), uid));
    if (!attendance) fail("permission-denied", "Only checked-in attendees may post.");
    const tagIds = data.taggedIds as string[];
    if (new Set(tagIds).size !== tagIds.length) fail("invalid-argument", "Duplicate tags are not allowed.");
    const invalidTags: string[] = [];
    for (const tagId of tagIds) {
      if (tagId === uid) { invalidTags.push(tagId); continue; }
      if (event.hostId === tagId ||
          (Array.isArray(event.coHostIds) && event.coHostIds.includes(tagId))) continue;
      if (!(await getData(tx, "attendance", attendanceIdFor(String(event.id), tagId)))) {
        invalidTags.push(tagId);
      }
    }
    if (invalidTags.length) fail("permission-denied", "Tags must be the builder or checked-in attendees.");
  } else {
    if (old.eventId !== data.eventId || old.authorId !== data.authorId ||
        old.body !== data.body || old.photoAsset !== data.photoAsset ||
        old.createdAt !== data.createdAt ||
        !await canViewPrivateSocial(tx, event, uid)) {
      fail("permission-denied", "Post identity and content are immutable.");
    }
    const changed = [
      "taggedIds", "likedByIds", "comments",
    ].filter((field) => !isDeepStrictEqual(old[field], data[field]));
    if (changed.length !== 1) fail("permission-denied", "Only one permitted post interaction may change at a time.");
    const field = changed[0];
    if (field === "taggedIds") {
      const before = stringList(old, "taggedIds");
      const after = stringList(data, "taggedIds");
      if (before.includes(uid) && !after.includes(uid) &&
          isDeepStrictEqual(before.filter((x) => x !== uid), after)) {
        tx.set(ref("posts", id), data);
        return;
      }
      fail("permission-denied", "Only a tagged user may remove their own tag.");
    }
    if (field === "likedByIds") {
      const before = stringList(old, "likedByIds");
      const after = stringList(data, "likedByIds");
      const expected = before.includes(uid)
        ? before.filter((x) => x !== uid)
        : [...before, uid];
      if (new Set(after).size === after.length && isDeepStrictEqual(expected, after)) {
        tx.set(ref("posts", id), data);
        return;
      }
      fail("permission-denied", "You may only toggle your own like.");
    }
    if (field === "comments") {
      const before = Array.isArray(old.comments) ? old.comments : [];
      const after = Array.isArray(data.comments) ? data.comments : [];
      if (after.length !== before.length + 1 ||
          !isDeepStrictEqual(after.slice(0, -1), before)) {
        fail("permission-denied", "Comments can only be appended.");
      }
      const comment = object(after[after.length - 1], "comment");
      if (comment.authorId !== uid || typeof comment.id !== "string" ||
          typeof comment.body !== "string" || comment.body.trim() === "") {
        fail("permission-denied", "You may only append your own non-empty comment.");
      }
      tx.set(ref("posts", id), data);
      return;
    }
  }
  tx.set(ref("posts", id), data);
}

async function saveReview(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (old || data.id !== id || data.authorId !== uid ||
      !Number.isInteger(data.rating) || (data.rating as number) < 1 ||
      (data.rating as number) > 5 || typeof data.text !== "string") {
    fail("permission-denied", "Reviews are immutable and require a rating from 1 to 5.");
  }
  const event = await requireEvent(tx, requiredString(data, "eventId"));
  const attendance = await getData(tx, "attendance", attendanceIdFor(String(event.id), uid));
  if (!attendance || event.status === "cancelled" || !isEnded(event)) {
    fail("permission-denied", "Only checked-in attendees may review after an event ends.");
  }
  const reviews = await tx.get(db.collection("reviews")
    .where("eventId", "==", event.id));
  if (reviews.docs.some((doc) => doc.get("authorId") === uid)) {
    fail("already-exists", "You already reviewed this event.");
  }
  tx.create(ref("reviews", id), data);
}

async function saveNotification(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (data.id !== id || data.userId !== uid) {
    fail("permission-denied", "Notifications may only be changed by their recipient.");
  }
  if (!old) {
    fail("permission-denied", "Notifications are created by trusted server actions.");
  }
  if (old.userId !== uid || !sameExcept(old, data, "read") ||
      (old.read === true && data.read !== true)) {
    fail("permission-denied", "You may only mark your own notification as read.");
  }
  tx.set(ref("notifications", id), data);
}

async function saveCase(
  tx: Transaction, uid: string, id: string, data: Data, old?: Data,
): Promise<void> {
  if (data.id !== id) fail("invalid-argument", "Case id mismatch.");
  if (!old) {
    if (data.reporterId !== uid || data.status !== "open" ||
        typeof data.details !== "string" || data.details.trim().length < 10 ||
        typeof data.category !== "string" || data.category.trim() === "" ||
        typeof data.assignedAdminId !== "string") {
      fail("invalid-argument", "A support report needs a category and at least 10 characters of detail.");
    }
    const admin = await requireUser(tx, data.assignedAdminId);
    if (admin.isAdmin !== true) fail("failed-precondition", "No admin is assigned yet.");
    if (data.outcome != null || data.decisionNote != null || data.closedAt != null) {
      fail("invalid-argument", "New support cases must be open.");
    }
  } else {
    const admin = await requireUser(tx, uid);
    if (old.assignedAdminId !== uid || admin.isAdmin !== true ||
        old.reporterId !== data.reporterId || old.category !== data.category ||
        old.details !== data.details || old.link !== data.link ||
        old.createdAt !== data.createdAt ||
        old.status !== "open" || data.status !== "closed" ||
        typeof data.decisionNote !== "string" || data.decisionNote.trim() === "" ||
        !["noAction", "removedPost", "warnedUser", "attendanceCorrected"].includes(String(data.outcome))) {
      fail("permission-denied", "Only the assigned admin may resolve an open case.");
    }
    if (data.outcome === "attendanceCorrected") {
      fail("failed-precondition", "Attendance correction requires the dedicated atomic support-resolution action.");
    }
    if (data.outcome === "removedPost") {
      const match = typeof old.link === "string" ? /post\/([A-Za-z0-9_]+)/.exec(old.link) : null;
      const post = match ? await getData(tx, "posts", match[1]) : undefined;
      if (post) fail("failed-precondition", "Remove the linked post before resolving this case.");
    }
  }
  tx.set(ref("cases", id), data);
}

export const createCarpsNotification = onCall({ region: REGION }, async (request) => {
  const uid = requireAuth(request.auth);
  const input = object(request.data, "request");
  const data = object(input.data, "data");
  checkFields(data, NOTIFICATION_FIELDS);
  const id = requiredString(data, "id");
  if (data.userId === uid) {
    fail("permission-denied", "This notification is not a self-notification.");
  }
  if (data.read !== false || typeof data.emailSimulated !== "boolean") {
    fail("invalid-argument", "New notifications must be unread.");
  }
  const kind = requiredString(data, "kind");
  const supportedKinds = [
    "joinRequest", "approved", "declined", "guestInvite", "coHostInvite",
    "coHostAccepted", "notice", "reminder", "checkedIn", "tagged", "comment",
    "cancelled", "supportUpdate", "supportAssigned",
  ];
  if (!supportedKinds.includes(kind)) {
    fail("invalid-argument", "Unknown notification kind.");
  }
  requiredString(data, "userId");
  requiredString(data, "title");
  requiredString(data, "body");
  dateMillis(data.createdAt, "createdAt");
  for (const field of ["eventId", "postId", "caseId"]) {
    if (data[field] != null && typeof data[field] !== "string") {
      fail("invalid-argument", `${field} must be a string or null.`);
    }
  }
  if (kind !== "reminder" && data.emailSimulated !== false) {
    fail("permission-denied", "Only reminders may be marked as simulated email.");
  }

  await db.runTransaction(async (tx) => {
    const notification = await getData(tx, "notifications", id);
    if (notification) fail("already-exists", "Notification already exists.");
    await requireUser(tx, String(data.userId));
    const actor = await requireUser(tx, uid);
    const targetId = String(data.userId);
    const eventId = typeof data.eventId === "string" ? data.eventId : null;
    const postId = typeof data.postId === "string" ? data.postId : null;
    const caseId = typeof data.caseId === "string" ? data.caseId : null;

    const checkEvent = async (): Promise<Data> => {
      if (!eventId || data.postId != null || data.caseId != null) {
        fail("invalid-argument", "This notification must refer only to an event.");
      }
      return requireEvent(tx, eventId);
    };
    const checkRegistration = async (event: Data): Promise<Data> => {
      const registrations = await tx.get(db.collection("registrations")
        .where("eventId", "==", event.id));
      const registration = registrations.docs
        .map((doc) => doc.data() as Data)
        .find((item) => item.userId === targetId);
      exists(registration, "The related registration was not found.");
      return registration;
    };
    const checkHostActor = (event: Data): void => {
      if (!hostingTeam(event, uid)) {
        fail("permission-denied", "Only the hosting team can send this notification.");
      }
    };
    const checkText = (title: string, body: string): void => {
      if (data.title !== title || data.body !== body) {
        fail("permission-denied", "Notification content does not match the related action.");
      }
    };

    switch (kind) {
      case "joinRequest": {
        const event = await checkEvent();
        const registration = await checkRegistration(event);
        if (registration.status !== "pending" || registration.userId !== uid ||
            !hostingTeam(event, targetId)) {
          fail("permission-denied", "Only a hosting-team member can be notified of a pending request.");
        }
        checkText(
          `${String(actor.displayName ?? "")} requested to join`,
          `${String(event.title)} · review in Guest roster`,
        );
        break;
      }
      case "approved":
      case "declined": {
        const event = await checkEvent();
        checkHostActor(event);
        const registration = await checkRegistration(event);
        if (kind === "approved") {
          const passId = requiredString(registration, "passId");
          const pass = await getData(tx, "passes", passId);
          if (registration.status !== "approved" || !pass ||
              pass.registrationId !== registration.id || pass.eventId !== eventId ||
              pass.userId !== targetId || pass.revoked === true) {
            fail("failed-precondition", "The guest does not have a valid approved pass.");
          }
          checkText(
            "You're in! Pass ready",
            `${String(event.title)}. Open My RSVPs to show your QR pass at the venue.`,
          );
        } else {
          if (registration.status !== "declined") {
            fail("failed-precondition", "The request has not been declined.");
          }
          checkText("Request not approved", `${String(event.title)}. No pass was issued.`);
        }
        break;
      }
      case "guestInvite":
      case "coHostInvite": {
        const event = await checkEvent();
        const invitations = await tx.get(db.collection("invitations")
          .where("eventId", "==", eventId));
        const invitation = invitations.docs
          .map((doc) => doc.data() as Data)
          .find((item) => item.inviteeId === targetId &&
            item.invitedById === uid &&
            item.kind === (kind === "guestInvite" ? "guest" : "coHost") &&
            item.status === "sent");
        exists(invitation, "The matching pending invitation was not found.");
        const inviterName = String(actor.displayName ?? "");
        if (kind === "coHostInvite") {
          if (event.hostId !== uid) {
            fail("permission-denied", "Only the builder can invite a co-host.");
          }
          const invitee = await requireUser(tx, targetId);
          if (invitee.hostingEnabled !== true) {
            fail("failed-precondition", "Co-hosts must have hosting enabled.");
          }
          checkText(
            `${inviterName} invited you to co-host`,
            `${String(event.title)}. You get hosting tools only after you accept.`,
          );
        } else {
          checkHostActor(event);
          if (hostingTeam(event, targetId)) {
            fail("failed-precondition", "Hosting-team members do not need guest invitations.");
          }
          checkText(
            `${inviterName} invited you to ${event.visibility === "private" ? "a private event" : "an event"}`,
            `${String(event.title)}. You can request to join; the host still decides.`,
          );
        }
        break;
      }
      case "coHostAccepted": {
        const event = await checkEvent();
        if (!Array.isArray(event.coHostIds) || !event.coHostIds.includes(uid)) {
          fail("permission-denied", "The actor is not an accepted co-host.");
        }
        const invitations = await tx.get(db.collection("invitations")
          .where("eventId", "==", eventId));
        const invitation = invitations.docs
          .map((doc) => doc.data() as Data)
          .find((item) => item.inviteeId === uid &&
            item.invitedById === targetId &&
            item.kind === "coHost" &&
            item.status === "accepted");
        exists(invitation, "The accepted co-host invitation was not found.");
        checkText(
          `${String(actor.displayName ?? "")} is now co-hosting`,
          String(event.title),
        );
        break;
      }
      case "notice":
      case "reminder":
      case "cancelled": {
        const event = await checkEvent();
        checkHostActor(event);
        const registration = await checkRegistration(event);
        if (kind === "notice") {
          const notices = Array.isArray(event.notices) ? event.notices : [];
          const found = notices.some((item) =>
            item !== null && typeof item === "object" &&
            (item as Data).text === data.body);
          if (!found || !["pending", "approved"].includes(String(registration.status))) {
            fail("failed-precondition", "The notice or active registration was not found.");
          }
          checkText(`Update: ${String(event.title)}`, String(data.body));
        } else if (kind === "reminder") {
          if (registration.status !== "approved") {
            fail("failed-precondition", "Reminders can only be sent to approved guests.");
          }
          checkText(`Reminder: ${String(event.title)}`, String(data.body));
        } else {
          if (event.status !== "cancelled" ||
              !["pending", "approved"].includes(String(registration.status))) {
            fail("failed-precondition", "The event or registration is not cancelled/active.");
          }
          checkText(
            `${String(event.title)} was cancelled`,
            "The listing stays available so your link still works.",
          );
        }
        break;
      }
      case "checkedIn": {
        const event = await checkEvent();
        const attendance = await getData(
          tx, "attendance", attendanceIdFor(String(event.id), targetId),
        );
        if (!attendance || attendance.scannedById !== uid ||
            !hostingTeam(event, uid) || attendance.passId == null) {
          fail("permission-denied", "Only the scanner who recorded this check-in may notify the guest.");
        }
        const pass = await getData(tx, "passes", String(attendance.passId));
        if (!pass || pass.revoked === true || pass.userId !== targetId ||
            pass.eventId !== event.id) {
          fail("failed-precondition", "The check-in does not have a valid pass.");
        }
        checkText(
          "Checked in",
          `Welcome to ${String(event.title)}! After it ends you can share your experience.`,
        );
        break;
      }
      case "tagged":
      case "comment": {
        if (!postId || !eventId || caseId != null) {
          fail("invalid-argument", "This notification must refer to a post and event.");
        }
        const post = await getData(tx, "posts", postId);
        exists(post, "Post not found.");
        if (post.eventId !== eventId) {
          fail("failed-precondition", "Post and event do not match.");
        }
        const event = await requireEvent(tx, eventId);
        if (kind === "tagged") {
          const tags = Array.isArray(post.taggedIds) ? post.taggedIds : [];
          if (post.authorId !== uid || !tags.includes(targetId)) {
            fail("permission-denied", "The actor must have tagged this notification recipient.");
          }
          const author = await requireUser(tx, uid);
          checkText(
            `${String(author.displayName ?? "")} tagged you`,
            `In a post about ${String(event.title)}`,
          );
        } else {
          const comments = Array.isArray(post.comments) ? post.comments : [];
          const hasComment = comments.some((item) =>
            item !== null && typeof item === "object" &&
            (item as Data).authorId === uid &&
            (item as Data).body === data.body);
          if (post.authorId !== targetId || uid === targetId || !hasComment) {
            fail("permission-denied", "Only the author of a new comment can notify the post author.");
          }
          checkText(
            `${String(actor.displayName ?? "")} commented`,
            String(data.body),
          );
        }
        if (!await canViewPrivateSocial(tx, event, uid)) {
          fail("permission-denied", "The actor cannot access this private event's social content.");
        }
        break;
      }
      case "supportAssigned": {
        if (!caseId || eventId != null || postId != null) {
          fail("invalid-argument", "This notification must refer only to a support case.");
        }
        const supportCase = await getData(tx, "cases", caseId);
        exists(supportCase, "Support case not found.");
        const admin = await requireUser(tx, targetId);
        if (supportCase.reporterId !== uid ||
            supportCase.assignedAdminId !== targetId ||
            supportCase.status !== "open" ||
            admin.isAdmin !== true) {
          fail("permission-denied", "Only the reporter can notify the assigned admin.");
        }
        checkText(
          "New issue assigned to you",
          `${String(supportCase.category)} · reported by a member`,
        );
        break;
      }
      case "supportUpdate": {
        if (!caseId || eventId != null || postId != null) {
          fail("invalid-argument", "This notification must refer only to a support case.");
        }
        const supportCase = await getData(tx, "cases", caseId);
        exists(supportCase, "Support case not found.");
        const admin = await requireUser(tx, uid);
        const expectedBody = supportCase.outcome === "noAction"
          ? "We reviewed your report and closed it without changes."
          : "We reviewed your report and took action. Thanks for helping keep CARPS safe.";
        if (supportCase.assignedAdminId !== uid ||
            supportCase.status !== "closed" ||
            admin.isAdmin !== true ||
            supportCase.reporterId !== targetId) {
          fail("permission-denied", "Only the assigned admin can notify the reporter.");
        }
        checkText("Your report was reviewed", expectedBody);
        break;
      }
    }
    tx.create(ref("notifications", id), {
      ...data,
      createdAt: new Date().toISOString(),
    });
  });
  return { ok: true };
});

export const resolveCarpsAttendanceCase = onCall({ region: REGION }, async (request) => {
  const uid = requireAuth(request.auth);
  const input = object(request.data, "request");
  const caseData = object(input.caseData, "caseData");
  if (!Object.prototype.hasOwnProperty.call(input, "attendanceData")) {
    fail("invalid-argument", "attendanceData is required (it may be null).");
  }
  const attendanceData = input.attendanceData === null
    ? null
    : object(input.attendanceData, "attendanceData");
  checkFields(caseData, CASE_FIELDS);
  if (attendanceData) checkFields(attendanceData, ATTENDANCE_FIELDS);
  const caseId = requiredString(caseData, "id");

  await db.runTransaction(async (tx) => {
    const currentCase = await getData(tx, "cases", caseId);
    exists(currentCase, "Support case not found.");
    const admin = await requireUser(tx, uid);
    if (admin.isAdmin !== true || currentCase.assignedAdminId !== uid) {
      fail("permission-denied", "Only the assigned admin can resolve this case.");
    }
    const linkedEvent = typeof currentCase.link === "string"
      ? /event\/([A-Za-z0-9_]+)/.exec(currentCase.link)?.[1]
      : undefined;
    if (!linkedEvent || typeof currentCase.reporterId !== "string") {
      fail("failed-precondition", "The case must link to an event and reporter.");
    }
    if (currentCase.status !== "open" ||
        caseData.status !== "closed" ||
        caseData.outcome !== "attendanceCorrected" ||
        caseData.hostConfirmed !== true ||
        currentCase.hostConfirmed === true ||
        !sameExcept(currentCase, caseData,
          "status", "outcome", "decisionNote", "closedAt", "hostConfirmed")) {
      fail("failed-precondition", "This case is not an open, confirmed attendance correction.");
    }
    const note = requiredString(caseData, "decisionNote");
    const event = await requireEvent(tx, linkedEvent);
    const registrations = await tx.get(db.collection("registrations")
      .where("eventId", "==", linkedEvent));
    const registration = registrations.docs
      .map((doc) => doc.data() as Data)
      .find((item) => item.userId === currentCase!.reporterId);
    if (!registration || registration.status !== "approved" ||
        typeof registration.passId !== "string") {
      fail("failed-precondition", "The reporter must have an approved registration.");
    }
    const userId = String(currentCase.reporterId);
    const attendanceId = attendanceIdFor(linkedEvent, userId);
    const existingAttendance = await getData(tx, "attendance", attendanceId);
    if (attendanceData === null) {
      if (!existingAttendance ||
          existingAttendance.eventId !== linkedEvent ||
          existingAttendance.userId !== userId ||
          existingAttendance.passId !== registration.passId ||
          !hostingTeam(event, String(existingAttendance.scannedById))) {
        fail("failed-precondition", "Null attendanceData requires an existing verified attendance record.");
      }
    } else {
      if (existingAttendance) {
        fail("already-exists", "Attendance has already been recorded.");
      }
      if (attendanceData.eventId !== linkedEvent ||
          attendanceData.userId !== userId ||
          attendanceData.passId !== registration.passId ||
          attendanceData.scannedById !== event.hostId ||
          attendanceData.arrivedAt !== event.start) {
        fail("failed-precondition", "Attendance data must match the approved registration and linked event.");
      }
      const pass = await getData(tx, "passes", registration.passId as string);
      if (!pass || pass.revoked === true ||
          pass.registrationId !== registration.id ||
          pass.userId !== userId ||
          pass.eventId !== linkedEvent) {
        fail("failed-precondition", "The approved registration does not have a valid pass.");
      }
    }
    const closedAt = new Date().toISOString();
    if (attendanceData !== null) {
      tx.create(ref("attendance", attendanceId), {
        eventId: linkedEvent,
        userId,
        arrivedAt: event.start,
        scannedById: event.hostId,
        passId: registration.passId,
      });
    }
    tx.set(ref("cases", caseId), {
      ...currentCase,
      status: "closed",
      outcome: "attendanceCorrected",
      decisionNote: note.trim(),
      closedAt,
      hostConfirmed: true,
    });
  });
  return { ok: true };
});

export const deleteCarpsPost = onCall({ region: REGION }, async (request) => {
  const uid = requireAuth(request.auth);
  const input = object(request.data, "request");
  const id = requiredString(input, "id");
  await db.runTransaction(async (tx) => {
    const post = await getData(tx, "posts", id);
    exists(post, "Post not found.");
    if (post.authorId !== uid) {
      const cases = await tx.get(db.collection("cases")
        .where("assignedAdminId", "==", uid));
      const referenced = cases.docs.some((doc) => {
        const link = doc.get("link");
        return doc.get("status") === "open" && typeof link === "string" &&
          new RegExp(`post/${escapeRegExp(id)}(?:$|[?#])`).test(link);
      });
      const admin = await getData(tx, "users", uid);
      if (!referenced || admin?.isAdmin !== true) {
        fail("permission-denied", "Only the author or an assigned admin reviewing this post can remove it.");
      }
    }
    tx.delete(ref("posts", id));
  });
  return { ok: true };
});

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
