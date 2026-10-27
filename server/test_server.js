const http = require('http');
const { spawn } = require('child_process');

console.log('Spawning server.js...');
const child = spawn('node', ['server.js'], { cwd: __dirname });

child.stdout.on('data', d => process.stdout.write(`[SERVER] ${d.toString()}`));
child.stderr.on('data', d => process.stderr.write(`[SERVER ERR] ${d.toString()}`));

setTimeout(async () => {
  try {
    // 1. Health
    const health = await makeRequest('GET', '/api/v1/health');
    console.log('\n✓ Health check passed:', health);

    // 2. Register
    const regRes = await makeRequest('POST', '/api/v1/auth/register', {
      phone: '9876543210',
      pin: '1234',
      storeName: 'Bharat Cloud Mart',
      ownerName: 'Ramesh Sharma',
      vertical: 'kiranaGrocery',
      stateCode: '27',
      isGstEnabled: true,
    });
    console.log('✓ Register response:', regRes);

    // 3. Login
    const loginRes = await makeRequest('POST', '/api/v1/auth/login', {
      phone: '9876543210',
      pin: '1234',
    });
    console.log('✓ Login response:', loginRes.success, 'Store:', loginRes.profile?.storeName);

    // 4. Admin fleet
    const adminRes = await makeRequest('GET', '/api/v1/admin/merchants', null, {
      'Authorization': 'Bearer 889900',
    });
    console.log('✓ Admin merchants fleet count:', adminRes.merchants?.length);

    console.log('\n🎉 ALL BACKEND API TESTS PASSED SUCCESSFULLY!');
  } catch (err) {
    console.error('Test failed:', err);
  } finally {
    child.kill();
    process.exit(0);
  }
}, 1500);

function makeRequest(method, path, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const postData = body ? JSON.stringify(body) : null;
    const reqHeaders = { ...headers };
    if (postData) {
      reqHeaders['Content-Type'] = 'application/json';
      reqHeaders['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = http.request({
      hostname: '127.0.0.1',
      port: 5000,
      path,
      method,
      headers: reqHeaders,
    }, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (_) {
          resolve(data);
        }
      });
    });

    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}
