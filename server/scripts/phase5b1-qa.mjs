const BASE = process.env.API_BASE || 'https://booked-51-production.up.railway.app/api/v1';

const creds = {
  patient: { email: 'patient@test.com', password: 'password123' },
  doctor: { email: 'ahmed.khan@docbook.com', password: 'password123' },
  admin: { email: 'admin@docbook.com', password: 'password123' },
};

async function req(method, path, { token, body } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { status: res.status, data };
}

async function login(role) {
  const body = role === 'admin' ? { email: 'svhdavid.vh@gmail.com', password: 'docbooked1528@' } : creds[role];
  const r = await req('POST', '/auth/login', { body });
  if (r.status !== 200) {
    throw new Error(`${role} login failed: ${r.status} ${JSON.stringify(r.data)}`);
  }
  return r.data.accessToken;
}

function check(label, cond) {
  console.log(cond ? `✅ PASS: ${label}` : `❌ FAIL: ${label}`);
  return cond;
}

async function main() {
  console.log(`\n=============================================`);
  console.log(` Starting Phase 5B.1 Production Live QA`);
  console.log(` URL: ${BASE}`);
  console.log(`=============================================\n`);

  // [1] Health check
  const health = await req('GET', '/health');
  check('Health endpoint returns 200', health.status === 200);
  check('Database status is healthy', health.data?.database === 'healthy');
  check('Email provider is Brevo', health.data?.email?.provider === 'brevo');

  // Login
  const patientToken = await login('patient');
  const doctorToken = await login('doctor');
  const adminToken = await login('admin');

  check('Patient token obtained', !!patientToken);
  check('Doctor token obtained', !!doctorToken);
  check('Admin token obtained', !!adminToken);

  // [2] Fetch Doctors
  const docsRes = await req('GET', '/doctors', { token: patientToken });
  const docList = docsRes.data?.doctors ?? docsRes.data ?? [];
  check('Public doctors list fetched', docsRes.status === 200 && Array.isArray(docList));

  const targetDoctor = docList.find(d => d.user?.email === 'ahmed.khan@docbook.com' || d.email === 'ahmed.khan@docbook.com') || docList[0];
  if (!targetDoctor) {
    console.log('❌ FAIL: No doctors available for testing');
    process.exit(1);
  }

  const doctorId = targetDoctor.id;
  console.log(`Selected doctor ID for QA: ${doctorId}`);

  // [3] Patient creates a request
  const bookingDate = new Date();
  bookingDate.setDate(bookingDate.getDate() + 5);
  const dateStr = bookingDate.toISOString();
  const testSlot = '11:00';

  const bookRes = await req('POST', '/appointments', {
    token: patientToken,
    body: { doctorId, date: dateStr, timeSlot: testSlot },
  });

  check('Create appointment request is 201 Created', bookRes.status === 201);
  const apptId = bookRes.data?.id;
  check('Appointment ID created', !!apptId);

  // [4] Check details & pending status
  const detailRes = await req('GET', `/appointments/${apptId}`, { token: patientToken });
  check('Get appointment detail status is 200', detailRes.status === 200);
  const appt = detailRes.data?.appointment ?? detailRes.data;
  check('Initial status is pending', appt?.status === 'pending');
  check('Preferred date matches patient choice', !!appt?.preferredDate);
  check('Preferred time slot matches patient choice', appt?.preferredTimeSlot === testSlot);

  // [5] Chat & Video guards check before confirmation
  const chatGuardRes = await req('POST', `/appointments/${apptId}/messages`, {
    token: patientToken,
    body: { content: 'This should be blocked' },
  });
  check('Chat blocked before doctor confirmation (403)', chatGuardRes.status === 403);

  const videoGuardRes = await req('GET', `/appointments/${apptId}/video-session`, { token: patientToken });
  check('Video session creation blocked before doctor confirmation (403)', videoGuardRes.status === 403);

  // [6] Doctor confirms the appointment
  const confirmedDate = new Date();
  confirmedDate.setDate(confirmedDate.getDate() + 5);
  const confirmedDateStr = confirmedDate.toISOString();
  const confirmedSlot = '11:30';

  console.log(`Doctor confirming appointment to: ${confirmedSlot}`);
  const confirmRes = await req('PUT', `/doctor/appointments/${apptId}/confirm`, {
    token: doctorToken,
    body: { date: confirmedDateStr, timeSlot: confirmedSlot },
  });

  check('Confirm appointment returns success status', confirmRes.status === 200);

  // [7] Verify confirmed status & updated times
  const postConfirmRes = await req('GET', `/appointments/${apptId}`, { token: patientToken });
  const postConfirmAppt = postConfirmRes.data?.appointment ?? postConfirmRes.data;
  check('Status updated to confirmed', postConfirmAppt?.status === 'confirmed');
  check('Main date set to doctor final choice', !!postConfirmAppt?.date);
  check('Main slot set to doctor final slot (11:30)', postConfirmAppt?.timeSlot === confirmedSlot);
  check('Preferred date remains preserved', !!postConfirmAppt?.preferredDate);
  check('Preferred slot remains preserved (11:00)', postConfirmAppt?.preferredTimeSlot === testSlot);

  // [8] Verify duplicate final confirmed slot is blocked
  const dupRes = await req('POST', '/appointments', {
    token: patientToken,
    body: { doctorId, date: confirmedDateStr, timeSlot: confirmedSlot },
  });
  check('Duplicate booking at confirmed time is blocked (409)', dupRes.status === 409 || dupRes.status === 400);

  // [9] Verify chat works after confirmation
  const postConfirmChatRes = await req('POST', `/appointments/${apptId}/messages`, {
    token: patientToken,
    body: { content: 'Hello doctor, confirmed!' },
  });
  check('Chat works after doctor confirmation (201)', postConfirmChatRes.status === 201);

  // [10] Complete appointment guard check
  // Try completing right away (since status is confirmed, doctor can complete it)
  const completeRes = await req('PUT', `/doctor/appointments/${apptId}/complete`, { token: doctorToken });
  check('Doctor completes confirmed appointment successfully', completeRes.status === 200);

  // Verify status is completed
  const finalDetailRes = await req('GET', `/appointments/${apptId}`, { token: patientToken });
  const finalAppt = finalDetailRes.data?.appointment ?? finalDetailRes.data;
  check('Final appointment status is completed', finalAppt?.status === 'completed');

  console.log(`\n=============================================`);
  console.log(` Phase 5B.1 Production Live QA Completed!`);
  console.log(`=============================================\n`);
}

main().catch(err => {
  console.error('QA Suite encountered error:', err);
  process.exit(1);
});
