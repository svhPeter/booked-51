#!/usr/bin/env node
/**
 * Phase 4 API validation (run with server on localhost:3000)
 */
const BASE = process.env.API_BASE || 'http://localhost:3000/api/v1';

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
  const r = await req('POST', '/auth/login', { body: creds[role] });
  if (r.status !== 200) throw new Error(`${role} login failed: ${r.status} ${JSON.stringify(r.data)}`);
  return r.data.accessToken;
}

function ok(label, cond) {
  console.log(cond ? `  OK  ${label}` : ` FAIL ${label}`);
  return cond;
}

async function main() {
  console.log('Phase 4 validation against', BASE);
  let passed = 0;
  let failed = 0;
  const check = (label, cond) => {
    if (ok(label, cond)) passed++;
    else failed++;
    return cond;
  };

  const health = await req('GET', '/health');
  check('health endpoint', health.status === 200 && health.data?.database === 'healthy');

  let patientToken = await login('patient');
  let doctorToken = await login('doctor');
  const adminToken = await login('admin');
  check('patient login', !!patientToken);
  check('doctor login', !!doctorToken);
  check('admin login', !!adminToken);

  const doctors = await req('GET', '/doctors', { token: patientToken });
  const docList = doctors.data?.doctors ?? doctors.data ?? [];
  check('public doctors list', doctors.status === 200 && Array.isArray(docList));
  check('all public doctors approved', docList.every((d) => d.isAvailable !== false));

  const doctor = docList[0];
  const doctorId = doctor?.id;
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  if (!doctorId) {
    console.log('  SKIP booking (no public doctors)');
  } else {
    let book = { status: 0 };
    let apptId = null;
    for (let i = 1; i <= 14; i++) {
      const d = new Date();
      d.setDate(d.getDate() + i);
      const dayName = dayNames[d.getDay()];
      const avail = doctor.availableDays ?? [];
      if (avail.length && !avail.includes(dayName)) continue;
      const dateStr = d.toISOString().split('T')[0];
      const slots = await req('GET', `/doctors/${doctorId}/slots?date=${dateStr}`, { token: patientToken });
      const slotList = slots.data?.slots ?? [];
      const timeSlot = slotList[0];
      if (!timeSlot) continue;
      book = await req('POST', '/appointments', {
        token: patientToken,
        body: { doctorId, date: d.toISOString(), timeSlot },
      });
      if (book.status === 201) {
        apptId = book.data?.id;
        break;
      }
      if (book.status === 409) continue;
    }
    if (apptId) {
      check('book appointment', book.status === 201);
      const detail = await req('GET', `/appointments/${apptId}`, { token: patientToken });
      check('GET appointment by id (patient)', detail.status === 200);
      check('detail has fee', detail.data?.appointment?.fee != null || detail.data?.fee != null);

      const bookedDoctorId = detail.data?.appointment?.doctorId ?? book.data?.doctorId;
      const bookedDoctor = docList.find((d) => d.id === bookedDoctorId);
      const docEmail = bookedDoctor?.email;
      if (docEmail) {
        const r = await req('POST', '/auth/login', {
          body: { email: docEmail, password: creds.doctor.password },
        });
        if (r.status === 200) doctorToken = r.data.accessToken;
      }

      const docDetail = await req('GET', `/appointments/${apptId}`, { token: doctorToken });
      check('GET appointment by id (doctor)', docDetail.status === 200);

      const wrongDoctorLogin = await req('POST', '/auth/login', {
        body: { email: 'usman.malik@docbook.com', password: creds.doctor.password },
      });
      const wrongDocToken = wrongDoctorLogin.data?.accessToken;
      const wrongDocMsgs = await req('GET', `/appointments/${apptId}/messages`, {
        token: wrongDocToken,
      });
      check('unrelated doctor blocked from chat', wrongDocMsgs.status === 403);

      const msg = await req('POST', `/appointments/${apptId}/messages`, {
        token: patientToken,
        body: { content: 'Phase4 validation message' },
      });
      check('send chat message', msg.status === 201);

      const hist = await req('GET', `/appointments/${apptId}/messages`, { token: doctorToken });
      check('list messages (doctor)', hist.status === 200 && (hist.data?.messages?.length ?? 0) >= 1);

        const adminMsgs = await req('GET', `/appointments/${apptId}/messages`, { token: adminToken });
        check('admin blocked from message bodies', adminMsgs.status === 403);

        const meta = await req('GET', `/admin/appointments/${apptId}/chat-meta`, { token: adminToken });
        check('admin chat meta', meta.status === 200);
        check('meta has no content field', !JSON.stringify(meta.data).includes('Phase4 validation'));

        const unread = await req('GET', `/appointments/${apptId}/messages/unread-count`, {
          token: doctorToken,
        });
        check('unread count', unread.status === 200);

        await req('PUT', `/appointments/${apptId}/messages/read`, { token: doctorToken });
        const unreadAfter = await req('GET', `/appointments/${apptId}/messages/unread-count`, {
          token: doctorToken,
        });
      check('mark read', unreadAfter.data?.count === 0);
    } else {
      check('book appointment', false);
    }
  }

  const payRoute = await req('POST', '/payments/create', {
    token: patientToken,
    body: { appointmentId: '00000000-0000-0000-0000-000000000000', provider: 'mock' },
  });
  check('payment route still exists (dormant)', payRoute.status === 404 || payRoute.status === 400 || payRoute.status === 201);

  const patProf = await req('GET', '/patients/me', { token: patientToken });
  check('patient profile GET', patProf.status === 200);

  const docProf = await req('GET', '/doctor/profile', { token: doctorToken });
  check('doctor profile GET', docProf.status === 200);

  const adminDoctors = await req('GET', '/admin/doctors', { token: adminToken });
  check('admin doctors list', adminDoctors.status === 200);

  const patientAdmin = await req('GET', '/admin/doctors', { token: patientToken });
  check('patient blocked from admin', patientAdmin.status === 403);

  console.log(`\nResults: ${passed} passed, ${failed} failed`);
  process.exit(failed > 0 ? 1 : 0);
}

main().catch((e) => {
  console.error('Validation aborted:', e.message);
  process.exit(1);
});
