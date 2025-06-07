const { SerialPort } = require('serialport');

const tangnano = new SerialPort({
    path: 'COM4', // Updated from Unix to Windows COM port
    baudRate: 115200,
});

let counter = 0;

tangnano.on('data', function (data) {
    console.log('Data In Text:', data.toString());
    console.log('Data In Hex:', data.toString('hex'));

    const binary = data.toString().split('').map((byte) => {
        return byte.charCodeAt(0).toString(2).padStart(8, '0');
    });
    console.log('Data In Binary: ', binary.join(' '));
    console.log("\n");

    counter += 1;
    tangnano.write(Buffer.from([counter]));
});

// Optional: log when port is opened
tangnano.on('open', () => {
    console.log('Serial port COM4 opened at 115200 baud.');
});

// Optional: error handling
tangnano.on('error', (err) => {
    console.error('Serial Port Error:', err.message);
});
