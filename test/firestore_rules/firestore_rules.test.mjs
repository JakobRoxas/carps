import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const projectId = 'demo-carps';
let environment;

const profile = (id, overrides = {}) => ({
  id,
  displayName: `Member ${id}`,
  username: `member_${id}`,
  avatarAsset: null,
  bio: '',
  area: null,
  interests: [],
  followingIds: [],
  hostingEnabled: false,
  builderName: null,
  builderAbout: null,
  isAdmin: false,
  termsAccepted: true,
  primaryRole: 'attendee',
  profileComplete: true,
  discoveryDone: true,
  contactDiscoveryOptIn: false,
  ...overrides,
});

const event = (id, hostId, visibility = 'private') => ({
  id,
  hostId,
  coHostIds: [],
  title: 'Community session',
  description: '',
  topic: 'Running & Fitness',
  venue: 'Park',
  area: 'Makati',
  start: new Date('2030-01-02T10:00:00Z'),
  end: new Date('2030-01-02T12:00:00Z'),
  visibility,
  coverAsset: null,
  capacity: null,
  featuredOnProfile: false,
  status: 'published',
  notices: [],
  seriesLabel: null,
});

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync('../../firestore.rules', 'utf8'),
    },
  });
});

after(async () => {
  await environment.cleanup();
});

beforeEach(async () => {
  await environment.clearFirestore();
});

test('profiles are public but members cannot set their admin permission', async () => {
  const memberDb = environment.authenticatedContext('member1').firestore();
  const otherDb = environment.authenticatedContext('member2').firestore();
  const ownProfile = doc(memberDb, 'profiles/member1');

  const creation = writeBatch(memberDb);
  creation.set(ownProfile, profile('member1'));
  creation.set(doc(memberDb, 'usernames/member_member1'), {
    userId: 'member1',
  });
  await assertSucceeds(creation.commit());
  await assertSucceeds(getDoc(doc(otherDb, 'profiles/member1')));
  await assertFails(
    updateDoc(ownProfile, {
      isAdmin: true,
    }),
  );
  await assertFails(
    setDoc(doc(memberDb, 'profiles/member3'), profile('member3')),
  );
  await assertFails(
    setDoc(ownProfile, {
      ...profile('member1'),
      email: 'private@example.com',
    }),
  );
});

test('private events require team membership or an invitation', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(
      doc(adminDb, 'profiles/host1'),
      profile('host1', { hostingEnabled: true }),
    );
    await setDoc(doc(adminDb, 'profiles/guest1'), profile('guest1'));
    await setDoc(doc(adminDb, 'events/private1'), event('private1', 'host1'));
  });

  const guestDb = environment.authenticatedContext('guest1').firestore();
  const hostDb = environment.authenticatedContext('host1').firestore();
  const outsiderDb = environment.authenticatedContext('outsider1').firestore();

  await assertFails(getDoc(doc(outsiderDb, 'events/private1')));

  const batch = writeBatch(hostDb);
  batch.set(doc(hostDb, 'invitations/invite1'), {
    id: 'invite1',
    eventId: 'private1',
    inviteeId: 'guest1',
    invitedById: 'host1',
    kind: 'guest',
    status: 'sent',
    createdAt: new Date(),
  });
  batch.set(doc(hostDb, 'eventAccess/private1_guest1'), {
    eventId: 'private1',
    userId: 'guest1',
    invitationId: 'invite1',
  });
  await assertSucceeds(batch.commit());
  await assertSucceeds(getDoc(doc(guestDb, 'events/private1')));
  await assertSucceeds(
    getDocs(
      query(
        collection(hostDb, 'invitations'),
        where('eventId', '==', 'private1'),
      ),
    ),
  );

  const accessQuery = query(
    collection(guestDb, 'eventAccess'),
    where('userId', '==', 'guest1'),
  );
  await assertSucceeds(getDocs(accessQuery));
  await assertFails(getDocs(collection(outsiderDb, 'eventAccess')));
});

test('users can create pending registrations only as themselves', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(doc(adminDb, 'events/public1'), event('public1', 'host1', 'public'));
  });

  const memberDb = environment.authenticatedContext('member1').firestore();
  await assertSucceeds(
    getDocs(
      query(
        collection(memberDb, 'events'),
        where('visibility', '==', 'public'),
      ),
    ),
  );
  const batch = writeBatch(memberDb);
  batch.set(doc(memberDb, 'registrations/reg_public1_member1'), {
    id: 'reg_public1_member1',
    eventId: 'public1',
    userId: 'member1',
    status: 'pending',
    requestedAt: new Date(),
    decidedAt: null,
    passId: null,
  });
  batch.set(doc(memberDb, 'registrationNotes/reg_public1_member1'), {
    registrationId: 'reg_public1_member1',
    eventId: 'public1',
    userId: 'member1',
    note: 'Please save me a seat.',
  });
  batch.set(doc(memberDb, 'eventAccess/public1_member1'), {
    eventId: 'public1',
    userId: 'member1',
    registrationId: 'reg_public1_member1',
  });
  await assertSucceeds(batch.commit());
  await assertSucceeds(
    setDoc(doc(memberDb, 'notifications/join_request_host1'), {
      id: 'join_request_host1',
      userId: 'host1',
      eventId: 'public1',
      kind: 'joinRequest',
      read: false,
    }),
  );
  await assertFails(
    setDoc(doc(memberDb, 'notifications/join_request_outsider'), {
      id: 'join_request_outsider',
      userId: 'outsider1',
      eventId: 'public1',
      kind: 'joinRequest',
      read: false,
    }),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(memberDb, 'registrations'),
        where('eventId', '==', 'public1'),
      ),
    ),
  );
  const outsiderDb = environment.authenticatedContext('outsider1').firestore();
  await assertFails(
    getDoc(doc(outsiderDb, 'registrationNotes/reg_public1_member1')),
  );
  const hostDb = environment.authenticatedContext('host1').firestore();
  await assertSucceeds(
    getDoc(doc(hostDb, 'registrationNotes/reg_public1_member1')),
  );
  await assertSucceeds(
    getDocs(
      query(
        collection(hostDb, 'registrationNotes'),
        where('eventId', '==', 'public1'),
      ),
    ),
  );
  await assertSucceeds(
    setDoc(doc(hostDb, 'notifications/notice_pending'), {
      id: 'notice_pending',
      userId: 'member1',
      eventId: 'public1',
      kind: 'notice',
      read: false,
    }),
  );
  await assertFails(
    setDoc(doc(hostDb, 'notifications/reminder_pending'), {
      id: 'reminder_pending',
      userId: 'member1',
      eventId: 'public1',
      kind: 'reminder',
      read: false,
    }),
  );

  await assertFails(
    setDoc(doc(memberDb, 'registrations/reg_public1_other1'), {
      id: 'reg_public1_other1',
      eventId: 'public1',
      userId: 'other1',
      status: 'pending',
      requestedAt: new Date(),
      decidedAt: null,
      passId: null,
    }),
  );
});

test('host approval, pass issuance, and check-in must agree atomically', async () => {
  const pendingRegistration = {
    id: 'reg_public1_guest1',
    eventId: 'public1',
    userId: 'guest1',
    status: 'pending',
    requestedAt: new Date(),
    decidedAt: null,
    passId: null,
  };
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(
      doc(adminDb, 'profiles/host1'),
      profile('host1', { hostingEnabled: true }),
    );
    await setDoc(doc(adminDb, 'profiles/guest1'), profile('guest1'));
    await setDoc(
      doc(adminDb, 'events/public1'),
      event('public1', 'host1', 'public'),
    );
    await setDoc(
      doc(adminDb, 'registrations/reg_public1_guest1'),
      pendingRegistration,
    );
  });

  const hostDb = environment.authenticatedContext('host1').firestore();
  const approvedRegistration = {
    ...pendingRegistration,
    status: 'approved',
    decidedAt: new Date(),
    passId: 'pass1',
  };
  const batch = writeBatch(hostDb);
  batch.set(doc(hostDb, 'passes/pass1'), {
    id: 'pass1',
    token: 'CARPS-unique-token',
    eventId: 'public1',
    userId: 'guest1',
    registrationId: pendingRegistration.id,
    issuedAt: new Date(),
    revoked: false,
  });
  batch.set(
    doc(hostDb, 'registrations/reg_public1_guest1'),
    approvedRegistration,
  );
  batch.set(doc(hostDb, 'registrationNotes/reg_public1_guest1'), {
    registrationId: pendingRegistration.id,
    eventId: 'public1',
    userId: 'guest1',
    note: 'Please save me a seat.',
  });
  batch.set(doc(hostDb, 'eventAccess/public1_guest1'), {
    eventId: 'public1',
    userId: 'guest1',
    registrationId: pendingRegistration.id,
  });
  await assertSucceeds(batch.commit());

  await assertSucceeds(
    setDoc(doc(hostDb, 'attendance/public1_guest1'), {
      eventId: 'public1',
      userId: 'guest1',
      arrivedAt: new Date(),
      scannedById: 'host1',
      passId: 'pass1',
    }),
  );
});

test('admins can remove reported posts authored by other members', async () => {
  await environment.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(
      doc(adminDb, 'profiles/admin1'),
      profile('admin1', { isAdmin: true }),
    );
    await setDoc(doc(adminDb, 'posts/post1'), {
      id: 'post1',
      eventId: 'public1',
      authorId: 'member1',
    });
  });

  const adminDb = environment.authenticatedContext('admin1').firestore();
  await assertSucceeds(deleteDoc(doc(adminDb, 'posts/post1')));
});
